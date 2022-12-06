#!/bin/bash -e
api_env="COMMUNITY_API_URL"
namespace="$(kubectl config view --minify -o jsonpath='{..namespace}')"
api_base_url="$(kubectl get deployment/hmpps-interventions-ui -ojson | jq -r '.spec.template.spec.containers[0].env[] | select(.name=="'$api_env'") | .value')"

path="$1"
echo "$(tput setaf 3)Calling API using default namespace ($namespace)$(tput sgr 0)" > /dev/stderr
echo "Using $(tput setaf 1)(needs VPN)$(tput sgr 0) $api_base_url$path" > /dev/stderr

if [[ "$1" == "" ]]; then
  echo "Empty path, excepted a GET query path" > /dev/stderr
  echo "Example: $0 /secure/offenders/crn/D002399/allOffenderManagers" > /dev/stderr
  exit 1
fi


curl -sS "$api_base_url$path" \
  -H "Authorization: Bearer $(./get_namespace_community_api_access_token.sh | jq -r .access_token)"
