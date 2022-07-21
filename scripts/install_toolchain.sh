#!/usr/bin/env bash
set -euo pipefail

HELM_VERSION="v3.7.1"
KUBERNETES_VERSION=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)

# install kubectl
curl -LO https://storage.googleapis.com/kubernetes-release/release/"$KUBERNETES_VERSION"/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl


# install helm
wget https://get.helm.sh/helm-"$HELM_VERSION"-linux-amd64.tar.gz
tar -xvzf helm-"$HELM_VERSION"-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/helm

# add helm repos
helm repo add stable https://charts.helm.sh/stable
helm repo add yilu-common https://yiluhub.github.io/common-chart/
helm repo update
