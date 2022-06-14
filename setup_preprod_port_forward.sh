#!/bin/bash -e

# ❗️do not store passwords here❗️
namespace="hmpps-interventions-preprod"
preprod_db_port="5433"
preprod_db_remote_host="cloud-platform-a326b0ca8eb97132.cdwm328dlye6.eu-west-2.rds.amazonaws.com"
preprod_port_forward_pod="port-forward-${USER//./-}"

function on_complete() {
  kubectl \
    --namespace="$namespace" \
    delete "pod/$preprod_port_forward_pod"
  exit
}
trap 'on_complete 2> /dev/null' SIGTERM SIGINT

kubectl \
  --namespace="$namespace" \
  run "$preprod_port_forward_pod" --image=ministryofjustice/port-forward \
    --port=5432 --env="REMOTE_HOST=$preprod_db_remote_host" --env="LOCAL_PORT=5432" --env="REMOTE_PORT=5432"

kubectl \
  --namespace="$namespace" \
  wait --for=condition=ready pod "$preprod_port_forward_pod"

echo
echo "✨ Turning on port-forwarding to $(tput setaf 2)$namespace$(tput sgr 0)"
echo "✨ Use $(tput setaf 3)Ctrl-C$(tput sgr 0) to exit and cleanup"
echo "🧑‍💻 Connect to the database via localhost:$preprod_db_port and $namespace postgres credentials"
echo

kubectl \
  --namespace="$namespace" \
  port-forward "$preprod_port_forward_pod" "$preprod_db_port:5432"
