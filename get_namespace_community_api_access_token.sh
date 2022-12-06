#!/bin/bash -e
namespace="$(kubectl config view --minify -o jsonpath='{..namespace}')"
echo "$(tput setaf 3)Getting access token using default namespace ($namespace)$(tput sgr 0)" > /dev/stderr

base_url="$(kubectl get deployment/hmpps-interventions-ui -ojson | jq -r '.spec.template.spec.containers[0].env[] | select(.name=="HMPPS_AUTH_URL") | .value')"
auth="$(kubectl get secret/hmpps-auth -ojson | jq -r '.data | map_values(@base64d) | ."interventions-ui-client-id.txt" + ":" + ."interventions-ui-client-secret.txt" | @base64')"

curl -sSX POST "$base_url/oauth/token?grant_type=client_credentials" \
 -H 'Content-Type: application/json' \
 -H "Authorization: Basic $auth"
