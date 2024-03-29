#!/bin/bash -e

function git_fetch() {
  local repo="$1"
  local full_repo="${GIT_ROOT:-..}/$repo/"
  (
    echo "$(tput setaf 3)fetching git repo $full_repo$(tput sgr 0)"
    cd "$full_repo"
    git fetch --quiet
  )
}

function get_git_version() {
  local repo="$1"
  local ref="$2"
  (
    cd "${GIT_ROOT:-..}/$repo/"
    git rev-parse "$ref"
  )
}

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
  echo
}

function show_migrations() {
  local spec="$1"
  git diff --name-only "$spec" -- src/main/resources/db/
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

    log="$(show_log "$older_sha..$newer_sha")"
    pending="$(echo "$log" | wc -l)"
    echo "$pending changes pending"

    migrations="$(show_migrations "$older_sha".."$newer_sha")"
    if [[ $migrations != "" ]]; then
      echo
      echo "🔥 review $(tput setaf 1)pending database migrations$(tput sgr 0)"
      echo "$migrations"
    fi

    bot_pattern="(dependabot|renovate)"

    echo
    echo "✨ feature commits"
    echo "$log" | grep -vE "$bot_pattern" || echo "nothing"

    echo
    echo "⬆️  dependency updates"
    echo "$log" | grep -E "$bot_pattern" || echo "nothing"
  )
}

function list_versions() {
  local repo="$1"
  git_fetch "$repo"
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
    local raw_version
    local sha
    if [[ "$env" =~ "git:" ]]; then
      raw_version="${env//git:/}"
      sha="$(get_git_version "$repo" "$raw_version")"
    else
      raw_version="$(get_deployed_version "$deployment" "$env")"
      sha="$(get_git_version "$repo" "$(echo "$raw_version" | cut -d'.' -f3)")"
    fi
    printf "%-26s" "has $raw_version ($sha)"
    echo

    last_sha="$sha" # assumes environments are listed in order of progression
    if [[ "$env" =~ "origin/main" ]]; then
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
  "git:origin/main" "hmpps-interventions-dev" "hmpps-interventions-preprod" "hmpps-interventions-prod"
list_versions "hmpps-interventions-service" "deployment/hmpps-interventions-service-api" \
  "git:origin/main" "hmpps-interventions-dev" "hmpps-interventions-preprod" "hmpps-interventions-prod"
