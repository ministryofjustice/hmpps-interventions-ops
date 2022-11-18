#!/bin/sh -e
kubectl apply \
  -f ./statefulset.yml \
  -f ./service.yml \
  -f ./ingress.yml \
  --namespace hmpps-interventions-prod
