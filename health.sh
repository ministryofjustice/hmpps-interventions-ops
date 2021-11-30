#!/bin/bash -e

function try_configured_urls() {
  local deployment="$1"
  local namespace="$2"

  local extracted_urls
  extracted_urls="$(kubectl get "deployment/$deployment" --namespace="$namespace" \
    -o=jsonpath='{.spec.template.spec.containers[].env}' | \
    jq -r '.[] | select(.name | endswith("URL")) | .value + "/health" | select(contains(".gov.uk") or contains(".dsd.io"))')"

  for url in $extracted_urls; do
    printf "%-40s" "$deployment"
    printf "%-40s" "on $namespace"
    printf "%s" "using $url: "
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
