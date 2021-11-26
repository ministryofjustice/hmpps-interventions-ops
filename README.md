# hmpps-interventions-pipeline

Deals with ensuring the continuous integration and deployment pipeline for interventions components
stays healthy beyond development environment

## Statuses

| What | Status |
| --- | --- |
| ui-service contracts | [![ui-service pact](https://pact-broker-prod.apps.live-1.cloud-platform.service.justice.gov.uk/matrix/provider/Interventions%20Service/latest/main/consumer/Interventions%20UI/latest/main/badge.svg)](https://pact-broker-prod.apps.live-1.cloud-platform.service.justice.gov.uk/matrix?q%5B%5Dpacticipant=Interventions+UI&q%5B%5Dtag=main&q%5B%5Dpacticipant=Interventions+Service&q%5B%5Dtag=main&latestby=cvpv&limit=100) |
| dependency health from configuration | `./health.sh` |
| deployed versions | `GIT_ROOT=/path/where/your/github/repos/are/cloned ./versions.sh`<br>use `SHOW_DIFF=1` as well for diffs |
