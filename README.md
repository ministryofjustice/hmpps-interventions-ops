# hmpps-interventions-ops

Tools used by the interventions dev team in day-to-day operations.

## Statuses

| What | Status |
| --- | --- |
| ui-service contracts | [![ui-service pact](https://pact-broker-prod.apps.live-1.cloud-platform.service.justice.gov.uk/matrix/provider/Interventions%20Service/latest/main/consumer/Interventions%20UI/latest/main/badge.svg)](https://pact-broker-prod.apps.live-1.cloud-platform.service.justice.gov.uk/matrix?q%5B%5Dpacticipant=Interventions+UI&q%5B%5Dtag=main&q%5B%5Dpacticipant=Interventions+Service&q%5B%5Dtag=main&latestby=cvpv&limit=100) |
| check dependency health from environment configuration | `./health.sh hmpps-interventions-ui hmpps-interventions-prod` |
| deployed versions | `./versions.sh`<br>use `SHOW_FILES=1` as well for what files changed<br>use `GIT_ROOT=/path/where/your/github/repos/are/cloned` if intervention repos are cloned somewhere else |
| check latest commit age on all remote branches | `./check_branch_age.sh`<br>use `GIT_ROOT=/path/where/your/github/repos/are/cloned` if intervention repos are cloned somewhere else |
| setup port forwarding to the pre-prod database to localhost:5433 | `./setup_preprod_port_forward.sh` |

## setup_preprod_port_forward.sh

This script semi-automates [the article in Cloud Platform user guide](https://user-guide.cloud-platform.service.justice.gov.uk/documentation/other-topics/rds-external-access.html#1-run-a-port-forward-pod).

The alternative approach of running queries would be to run a `psql` container, but that has significant drawbacks:

- all input and output is automatically log collected
- this means any accidental exposure of personal information would be retained in the logs

This port-forwarding method provides an alternative that still requires credentials to access the namespace, but does
not expose sensitive information accidentally.

:rotating_light: Please read [data at rest on MoJ-issued laptops](https://security-guidance.service.justice.gov.uk/data-handling-and-information-sharing-guide/#data-at-rest-on-moj-issued-laptops)
for guidance on storing sensitive data (query output).

### Usage

```
$ ./setup_preprod_port_forward.sh
pod/port-forward-davidlantos created
pod/port-forward-davidlantos condition met

✨ Turning on port-forwarding to hmpps-interventions-preprod
✨ Use Ctrl-C to exit and cleanup
🧑‍💻 Connect to the database via localhost:5433 and hmpps-interventions-preprod postgres credentials

Forwarding from 127.0.0.1:5433 -> 5432
Forwarding from [::1]:5433 -> 5432
```

To exit, press <kbd>Ctrl</kbd>+<kbd>C</kbd> and wait for the pod to terminate.

### Connecting to the forwarded database

View the credentials with `kubectl get secret/postgres -n hmpps-interventions-preprod -ojson | jq '.data | map_values(@base64d)'`

You can use any database tool.
If you want to use `psql` locally, connect via `psql -h localhost -p 5433 -U database_username database_name`:

```
$ psql -h localhost -p 5433 -U cpS00... dba32...
<password prompt>
```
