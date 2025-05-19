#!/bin/bash -e

# ❗️do not store passwords here❗️
namespace="Namespace to connect"
environment_db_port="<<port>>"
environment_db_remote_host="<<Get the DB URI from k8s secrets>>"
environment_port_forward_pod="port-forward-${USER//./-}"

function on_complete() {
  kubectl \
    --namespace="$namespace" \
    delete "pod/$environment_port_forward_pod"
  exit
}
trap 'on_complete 2> /dev/null' SIGTERM SIGINT

kubectl \
  --namespace="$namespace" \
  run "$environment_port_forward_pod" --image=ministryofjustice/port-forward \
    --port=5432 --env="REMOTE_HOST=$environment_db_remote_host" --env="LOCAL_PORT=5432" --env="REMOTE_PORT=5432"

kubectl \
  --namespace="$namespace" \
  wait --for=condition=ready pod "$environment_port_forward_pod"

echo
echo "✨ Turning on port-forwarding to $(tput setaf 2)$namespace$(tput sgr 0)"
echo "✨ Use $(tput setaf 3)Ctrl-C$(tput sgr 0) to exit and cleanup"
echo "🧑‍💻 Connect to the database via localhost:$environment_db_port and $namespace postgres credentials"
echo

kubectl \
  --namespace="$namespace" \
  port-forward "$environment_port_forward_pod" "$environment_db_port:5432"
