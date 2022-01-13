#!/bin/bash -e

function try_configured_urls() {
  local deployment="$1"
  local namespace="$2"

  local extracted_urls
  extracted_urls="$(kubectl get "deployment/$deployment" --namespace="$namespace" \
    -o=jsonpath='{.spec.template.spec.containers[].env}' | \
    jq -r '.[] | select(.name | endswith("URL")) | select(.value | contains(".gov.uk") or contains(".dsd.io")) |
      .name + "," + .value + "/health"')"

  for kv in $extracted_urls; do
    IFS=',' read -r -a elems <<< "$kv"
    env_var="${elems[0]}"
    url="${elems[1]}"

    printf "found %-40s checking %s: " "$env_var" "$url"
    check="⛔️ down"
    if curl "$url" --max-time 5 --silent -o/dev/null; then
      check="✅ up"
    fi
    echo "$check"
  done
}

deployment="$1"
namespace="$2"
if [ "" == "$deployment" ] || [ "" == "$namespace" ]; then
  echo "❗️ Usage: $0 <deployment_name> <namespace>"
  echo "Example: $0 hmpps-interventions-ui hmpps-interventions-preprod"
  exit 1
fi

echo "$(tput setaf 3)$deployment$(tput sgr 0) on $(tput setaf 3)$namespace$(tput sgr 0)"
try_configured_urls "$deployment" "$namespace"
