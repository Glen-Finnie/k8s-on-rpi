#!/usr/bin/env bash

set -e

curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash
sudo mv kustomize /usr/local/bin
sudo chown root:root /usr/local/bin/kustomize
