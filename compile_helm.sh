#!/bin/bash -e

repo="$1"
env="$2"
if [ "" == "$repo" ] || [ "" == "$env" ]; then
  echo "❗️ Usage: $0 <repo_name> <env>"
  echo "Example: $0 hmpps-interventions-service dev"
  exit 1
fi

echo "compiling $(tput setaf 3)$repo$(tput sgr 0)" >/dev/stderr

helm_chart="$repo" # assuming it is the same
repo_dir="${GIT_ROOT:-..}/$repo"
test_tag="hmpps-interventions-ops"
(
  cd "$repo_dir/helm_deploy"
  helm dependency update "$helm_chart" >/dev/stderr
  helm template \
    --namespace="hmpps-interventions-$env" \
    --set image.tag="$test_tag" \
    --set generic-service.image.tag="$test_tag" \
    "$helm_chart" \
    "$helm_chart" \
    --values="values-$env.yaml"
)
