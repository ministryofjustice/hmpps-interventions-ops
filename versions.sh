#!/bin/bash -e

function get_deployed_version() {
  local deployment="$1"
  local namespace="$2"
  kubectl get "deployment/$deployment" --namespace="$namespace" \
      -o=jsonpath='{.metadata.labels.app\.kubernetes\.io/version}'
}

function show_changelog() {
  local repo="$1"
  local older_sha="$2"
  local newer_sha="$3"
  (
    cd "$GIT_ROOT/$repo/"
    git fetch --quiet
    PAGER="" git log --oneline --no-decorate --committer='noreply@github.com' --grep='#' "$older_sha..$newer_sha"
    PAGER="" git diff --stat "$older_sha..$newer_sha"
  )
}

function list_versions() {
  local repo="$1"
  shift
  local envs=("$@")
  local circle_url="https://app.circleci.com/pipelines/github/ministryofjustice/$repo?branch=main"

  local prod_sha=""
  local dev_sha=""
  for env in "${envs[@]}"; do
    printf "%-40s" "$repo"
    printf "%-40s" "on $env"
    local version
    version="$(get_deployed_version "$repo" "$env")"
    printf "%-26s" "has $version"
    echo

    sha="$(echo "$version" | cut -d'.' -f3)"
    if [[ "$env" =~ "prod" ]]; then
      prod_sha="$sha"
    fi
    if [[ "$env" =~ "dev" ]]; then
      dev_sha="$sha"
    fi
  done

  echo
  echo "🐿  deploy $repo from: $circle_url"
  echo "unreleased changes in $repo $prod_sha..$dev_sha:"
  show_changelog "$repo" "$prod_sha" "$dev_sha"
  echo
}

list_versions "hmpps-interventions-ui" \
  "hmpps-interventions-research" "hmpps-interventions-dev" "hmpps-interventions-preprod" "hmpps-interventions-prod"
list_versions "hmpps-interventions-service" \
  "hmpps-interventions-research" "hmpps-interventions-dev" "hmpps-interventions-preprod" "hmpps-interventions-prod"
