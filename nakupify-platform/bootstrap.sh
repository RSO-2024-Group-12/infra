#!/bin/bash

#set -e
set -o pipefail

# list the currently active kubectl context and ask for confirmation
CURRENT_CONTEXT=$(kubectl config current-context)
echo "Current kubectl context is: $CURRENT_CONTEXT"
read -p "Is this the correct context to use? (y/n): " CONFIRM
if [[ "$CONFIRM" != "y" ]]; then
  echo "Aborting bootstrap."
  exit 1
fi

# now install OLM
echo "Installing Operator Lifecycle Manager (OLM)..."
curl -L https://github.com/operator-framework/operator-lifecycle-manager/releases/download/v0.38.0/install.sh | bash -s v0.38.0
RES=$?
if [ $RES -ne 0 ]; then
  echo "OLM installation failed with exit code $RES."
  exit $RES
fi
echo "OLM installation complete."
# echo "Waiting for OLM pods to be ready..."
# kubectl wait --for=condition=Available=True --timeout=300s deployment/olm-operator -n olm
# kubectl wait --for=condition=Available=True --timeout=300s deployment/catalog-operator -n olm
# echo "OLM pods are ready."