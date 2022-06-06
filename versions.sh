#!/bin/bash -e

function get_deployed_version() {
  local deployment="$1"
  local namespace="$2"
  kubectl get "$deployment" --namespace="$namespace" \
      -o=jsonpath='{.spec.template.spec.containers[].image}' | \
      sed 's|.*:\(.*\)|\1|'
}

function show_files() {
  if [[ "$SHOW_FILES" == "" ]]; then
    return
  fi

  local repo="$1"
  local older_sha="$2"
  local newer_sha="$3"
  (
    cd "${GIT_ROOT:-..}/$repo/"
    git fetch --quiet
    echo -e "\n--diff--"
    PAGER="" git diff --stat "$older_sha..$newer_sha"
  )
}

function show_log() {
  local git_format='%C(yellow)%h%Creset %s %Cblue(%cr, %ch)%Creset'
  local spec="$1"
  shift
  PAGER="" git log --oneline --no-decorate --color --pretty=format:"$git_format" --committer='noreply@github.com' --grep='#' $* "$spec" \
    | sed 's/Merge pull request /PR /g; s|from ministryofjustice/dependabot/|'"$(tput setaf 14)"':dependabot:'"$(tput sgr 0)"'|g; s|from ministryofjustice/||g'
}

function show_changelog() {
  local repo="$1"
  local older_sha="$2"
  local newer_sha="$3"
  local repo_dir="${GIT_ROOT:-..}/$repo"
  if [[ "$older_sha" == "$newer_sha" ]]; then
    echo "✨ $(tput setaf 2)no unreleased changes in $repo$(tput sgr 0)"
    return
  else
    echo "🚧 $(tput setaf 3)unreleased changes in $repo$(tput sgr 0) $older_sha..$newer_sha:"
  fi
  (
    cd "$repo_dir/"
    git fetch --quiet

    echo
    echo "✨ feature commits"
    show_log "$older_sha..$newer_sha" | grep -v "dependabot" || echo "nothing"

    echo
    echo "⬆️  dependency updates"
    show_log "$older_sha..$newer_sha" | grep "dependabot" || echo "nothing"
  )
}

function list_versions() {
  local repo="$1"
  shift
  local deployment="$1"
  shift
  local envs=("$@")
  local circle_url="https://app.circleci.com/pipelines/github/ministryofjustice/$repo?branch=main"

  local last_sha=""
  local dev_sha=""
  for env in "${envs[@]}"; do
    printf "%-50s" "$repo"
    printf "%-40s" "on $env"
    local version
    version="$(get_deployed_version "$deployment" "$env")"
    printf "%-26s" "has $version"
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
  show_files "$repo" "$last_sha" "$dev_sha"
  echo
}

list_versions "hmpps-interventions-ui" "deployment/hmpps-interventions-ui" \
  "hmpps-interventions-dev" "hmpps-interventions-preprod" "hmpps-interventions-prod"
list_versions "hmpps-interventions-service" "deployment/hmpps-interventions-service-api" \
  "hmpps-interventions-dev" "hmpps-interventions-preprod" "hmpps-interventions-prod"
list_versions "hmpps-delius-interventions-event-listener" "deployment/hmpps-delius-interventions-event-listener" \
  "hmpps-interventions-dev" "hmpps-interventions-preprod"
