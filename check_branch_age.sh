#!/bin/bash -e

git_format='%D: %C(yellow)%h%Creset %Cblue(%cr)%Creset'
function check_branch_ages() {
  local repo="$1"
  local repo_dir="$GIT_ROOT/$repo"
  echo
  echo "🔎 $(tput setaf 3)Checking unmerged branches in $repo$(tput sgr 0):"
  (
    cd "$repo_dir/"
    git fetch --all --prune --quiet
    branches="$(git branch --remote --list --no-merged=origin/main --sort=committerdate)"
    for branch in $branches; do
      PAGER="" git show --no-patch --oneline --no-decorate --color --pretty=format:"$git_format" "$branch"
      echo
    done
  )
}

check_branch_ages "hmpps-interventions-ui"
check_branch_ages "hmpps-interventions-service"
check_branch_ages "hmpps-delius-interventions-event-listener"
