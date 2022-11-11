#!/bin/bash -e

repo="$1"
if [ "" == "$repo" ]; then
  echo "❗️ Usage: $0 <repo_name>"
  echo "Example: $0 hmpps-interventions-service"
  exit 1
fi

echo "compiling $(tput setaf 3)$repo$(tput sgr 0)" >/dev/stderr

helm_chart="$repo" # assuming it is the same
repo_dir="${GIT_ROOT:-..}/$repo"
test_tag="hmpps-interventions-ops/show-kubectl.sh"
(
  cd "$repo_dir/helm_deploy"
  helm dependency build "$helm_chart" >/dev/stderr
  helm template \
    --set image.tag="$test_tag" \
    --set generic-service.image.tag="$test_tag" \
    "$helm_chart" \
    "$helm_chart" \
    --values=values-prod.yaml
)
