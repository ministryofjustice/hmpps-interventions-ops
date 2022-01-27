#!/bin/bash -e

function get_deployed_version() {
  local deployment="$1"
  local namespace="$2"
  local context="$3"
  kubectl get "deployment/$deployment" --context="$context" --namespace="$namespace" \
      -o=jsonpath='{.spec.template.spec.containers[].image}' | \
      sed 's|.*:\(.*\)|\1|'
}

function show_diff() {
  if [[ "$SHOW_DIFF" == "" ]]; then
    return
  fi

  local repo="$1"
  local older_sha="$2"
  local newer_sha="$3"
  (
    cd "$GIT_ROOT/$repo/"
    git fetch --quiet
    echo -e "\n--diff--"
    PAGER="" git diff --stat "$older_sha..$newer_sha"
  )
}

git_format='%C(yellow)%h%Creset %s %Cblue(%cr)%Creset'
function show_changelog() {
  local repo="$1"
  local older_sha="$2"
  local newer_sha="$3"
  local repo_dir="$GIT_ROOT/$repo"
  if [[ "$older_sha" == "$newer_sha" ]]; then
    echo "✨ $(tput setaf 2)no unreleased changes in $repo$(tput sgr 0)"
    return
  else
    echo "🚧 $(tput setaf 3)unreleased changes in $repo$(tput sgr 0) $older_sha..$newer_sha:"
    echo "--commits from $repo_dir--"
  fi
  (
    cd "$repo_dir/"
    git fetch --quiet
    PAGER="" git log --oneline --no-decorate --color --pretty=format:"$git_format" --committer='noreply@github.com' --grep='#' "$older_sha..$newer_sha" \
      | sed 's/Merge pull request /PR /g; s|from ministryofjustice/dependabot/|'"$(tput setaf 14)"':dependabot:'"$(tput sgr 0)"'|g; s|from ministryofjustice/||g'
    echo
  )
}

function list_versions() {
  local repo="$1"
  shift
  local envs=("$@")
  local circle_url="https://app.circleci.com/pipelines/github/ministryofjustice/$repo?branch=main"

  local last_sha=""
  local dev_sha=""
  for env in "${envs[@]}"; do
    local context="${K8S_LIVE1_CONTEXT:-live-1.cloud-platform.service.justice.gov.uk}"
    if [[ "$env" =~ ":live" ]]; then
      context="${K8S_LIVE_CONTEXT:-live.cloud-platform.service.justice.gov.uk}"
      env="${env/:live/}"
    fi

    printf "%-50s" "$repo"
    printf "%-40s" "on $env"
    local version
    version="$(get_deployed_version "$repo" "$env" "$context")"
    printf "%-26s" "has $version"
    printf "%s" " on $context"
    echo

    sha="$(echo "$version" | cut -d'.' -f3)"
    last_sha="$sha" # assumes environments are listed in order of progression
    if [[ "$env" =~ "-dev" ]]; then
      dev_sha="$sha"
    fi
  done

  echo
  echo "🐿  deploy $repo from: $circle_url"
  show_changelog "$repo" "$last_sha" "$dev_sha"
  show_diff "$repo" "$last_sha" "$dev_sha"
  echo
}

list_versions "hmpps-interventions-ui" \
  "hmpps-interventions-dev:live" "hmpps-interventions-preprod:live" "hmpps-interventions-prod:live"
list_versions "hmpps-interventions-service" \
  "hmpps-interventions-dev:live" "hmpps-interventions-preprod:live" "hmpps-interventions-prod:live" "hmpps-interventions-prod"
list_versions "hmpps-delius-interventions-event-listener" \
  "hmpps-interventions-dev:live" "hmpps-interventions-preprod:live"
