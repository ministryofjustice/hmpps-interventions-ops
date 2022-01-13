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

    printf "%-40s" "$deployment"
    printf "%-40s" "on $namespace"
    printf "found %-40s checking %s: " "$env_var" "$url"
    check="⛔️ down"
    if curl "$url" --max-time 5 --silent -o/dev/null; then
      check="✅ up"
    fi
    echo "$check"
  done
}

for s in "ui" "service"; do
  for n in "dev" "preprod" "prod"; do
    try_configured_urls "hmpps-interventions-$s" "hmpps-interventions-$n"
    echo
  done
done
