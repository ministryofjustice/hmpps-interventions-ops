#!/bin/bash -e

# ❗️do not store passwords here❗️
namespace="${1}"
if [ -z "$namespace" ]; then
  echo '❌ Missing namespace.'
  echo "Usage: $0 <namespace>"
  exit 1
fi

db_port="5433"
db_remote_host="$(kubectl get secret/postgres14 --namespace="$namespace" -ojson | jq -r '.data.rds_instance_address | @base64d')"
port_forward_pod="port-forward-${USER//./-}"

function on_complete() {
  kubectl \
    --namespace="$namespace" \
    delete "pod/$port_forward_pod"
  exit
}
trap 'on_complete 2> /dev/null' SIGTERM SIGINT

kubectl \
  --namespace="$namespace" \
  run "$port_forward_pod" --image=ministryofjustice/port-forward \
    --port=5432 --env="REMOTE_HOST=$db_remote_host" --env="LOCAL_PORT=5432" --env="REMOTE_PORT=5432"

kubectl \
  --namespace="$namespace" \
  wait --for=condition=ready pod "$port_forward_pod"

echo
echo "✨ Turning on port-forwarding to $(tput setaf 2)$namespace$(tput sgr 0)"
echo "✨ Use $(tput setaf 3)Ctrl-C$(tput sgr 0) to exit and cleanup"
echo "🧑‍💻 Connect to the database via localhost:$db_port and $namespace postgres credentials"
echo

kubectl \
  --namespace="$namespace" \
  port-forward "$port_forward_pod" "$db_port:5432"
