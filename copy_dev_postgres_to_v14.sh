#!/bin/sh -e
target_namespace="hmpps-interventions-dev"

echo "Going to stop and migrate $target_namespace"
echo "Please verify             ^^^^^^^^^^^^^^^^^^^^^^^^^^^ and abort if necessary."
sleep 2


echo
echo "✨ Stopping UI"
kubectl scale \
  --namespace="$target_namespace" \
  --replicas=0 \
  --timeout=5m \
  deployment/hmpps-interventions-ui


echo
echo "✨ Waiting for all pods to fully shut down"
kubectl wait --for=delete --timeout=-1s \
  --namespace="$target_namespace" \
  --selector=release=hmpps-interventions-ui \
  pod


echo
echo "✨ Stopping API/jobs"
kubectl scale \
  --namespace="$target_namespace" \
  --replicas=0 \
  --timeout=5m \
  --selector=app.kubernetes.io/name=hmpps-interventions-service \
  deployment


echo
echo "✨ Waiting for all pods to fully shut down"
kubectl wait --for=delete --timeout=-1s \
  --namespace="$target_namespace" \
  --selector=release=hmpps-interventions-service \
  pod


echo
echo "✨ Starting copy job"

kubectl apply \
  --namespace="$target_namespace" \
  --filename=./copy-from-postgres10-to-postgres14.yaml

echo
echo "✨ Waiting for copy job to finish"

kubectl wait --for=condition=Complete --timeout=-1s \
  --namespace="$target_namespace" \
  job/db-copy-once


echo
echo "⏭  Done: deploy the postgres14 config change"
echo "🔃 To retry, delete job/db-copy-once and run this script again"
