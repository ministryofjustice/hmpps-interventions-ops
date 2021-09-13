#!/bin/bash -e
sensitive_dir="$(dirname "$0")"
snapshot_time="$(date '+%Y%m%d-%H%M%S')"

# ❗️do not store passwords here❗️
__prod_db_port="5431"
__prod_db_user="cpL8k8WgOw"
__prod_db_name="dbe4573fa1c83bbbb9"
__prod_db_remote_host="cloud-platform-e4573fa1c83bbbb9.cdwm328dlye6.eu-west-2.rds.amazonaws.com"
__prod_port_forward_pod="port-forward-prod-$snapshot_time"

# ❗️do not store passwords here❗️
preprod_db_port="5433"
preprod_db_user="cpS00AbRsu"
preprod_db_name="dba326b0ca8eb97132"
preprod_db_remote_host="cloud-platform-a326b0ca8eb97132.cdwm328dlye6.eu-west-2.rds.amazonaws.com"
preprod_port_forward_pod="port-forward-preprod-$snapshot_time"

function setup_port_forward() {
  namespace="$1"
  pod_name="$2"
  remote_host="$3"
  local_port="$4"

  kubectl \
    --namespace="$namespace" run "$pod_name" --image=ministryofjustice/port-forward \
    --port=5432 --env="REMOTE_HOST=$remote_host" --env="LOCAL_PORT=5432" --env="REMOTE_PORT=5432"

  kubectl --namespace="$namespace" wait --for=condition=ready pod "$pod_name"

  kubectl --namespace="$namespace" port-forward "$pod_name" "$local_port:5432" &
  while ! nc -z localhost "$local_port"; do sleep 0.3; done
}


echo
echo "Creating production port forward pod"
setup_port_forward hmpps-interventions-prod "$__prod_port_forward_pod" "$__prod_db_remote_host" "$__prod_db_port"

echo
echo "Creating pre-production port forward pod"
setup_port_forward hmpps-interventions-preprod "$preprod_port_forward_pod" "$preprod_db_remote_host" "$preprod_db_port"


echo
echo "🔐 Please enter $(tput setaf 1)production$(tput sgr 0) database password for pg_dump:"
pg_dump --no-owner --no-privileges --clean --if-exists \
  -h "localhost" -p "$__prod_db_port" -U "$__prod_db_user" "$__prod_db_name" \
  > "$sensitive_dir/prod_data_snapshot_$snapshot_time.sql"

echo "Terminating prod port-forward"
kill %1

echo
echo "🔐 Please enter $(tput setaf 3)pre-production$(tput sgr 0) database password to $(tput setaf 1)wipe it$(tput sgr 0) and restore prod data on it:"
psql -h "localhost" -p "$preprod_db_port" -U "$preprod_db_user" "$preprod_db_name" \
  --file="$sensitive_dir/prod_data_snapshot_$snapshot_time.sql"

echo "Terminating preprod port-forward"
kill %2

echo
echo "Cleaning up data"
rm -v "$sensitive_dir/prod_data_snapshot_$snapshot_time.sql"


echo
echo "Cleaning up port-forward pods"
kubectl --namespace=hmpps-interventions-prod delete "pod/$__prod_port_forward_pod"
kubectl --namespace=hmpps-interventions-preprod delete "pod/$preprod_port_forward_pod"
