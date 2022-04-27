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
