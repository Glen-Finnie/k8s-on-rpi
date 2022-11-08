#!/usr/bin/env bash

set -e

source /etc/lsb-release
if [ "$DISTRIB_RELEASE" != "22.04" ]; then
    echo
    echo "#################################"
    echo "############# ERROR #############"
    echo "#################################"
    echo
    echo "This script is intended for Ubuntu 22.04"
    echo "You're using: ${DISTRIB_DESCRIPTION}"
    exit 1
fi

### Set up auto complete and alias for kubectl
if ! grep -q 'source <(kubectl completion bash)' ~/.bashrc; then
    echo 'source <(kubectl completion bash)' >> ~/.bashrc
fi
if ! grep -q 'alias k=kubectl' ~/.bashrc; then
    echo 'alias k=kubectl' >> ~/.bashrc
fi
if ! grep -q 'complete -F __start_kubectl k' ~/.bashrc; then
    echo 'complete -F __start_kubectl k' >> ~/.bashrc
fi

### Check ip_forward is enabled
echo
echo "#####################################"
echo "######## net.ipv4.ip_forward ########"
echo "# The value below must be 1 (not 0) #"
sysctl net.ipv4.ip_forward

### Disable swap
swapoff -a

### From https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/

### install containerd
CONTAINERD_VERSION=1.5.9-0ubuntu3
sudo apt --yes update
sudo apt --yes install containerd=${CONTAINERD_VERSION}
sudo apt-mark hold containerd

echo
echo "######## containerd version ########"
echo
containerd --version
echo

### Enable Kernal overlay & br_netfilter Modules required by containerd
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

echo
echo "########### overlay #############"
lsmod | grep overlay
echo

echo
echo "######### br_netfilter ##########"
lsmod | grep br_netfilter
echo

### Create the containerd config file
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null

### install kubeadm kubelet kubectl
KUBE_VERSION=1.25.0
sudo apt --yes install apt-transport-https ca-certificates curl

sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt update
sudo apt --yes install kubelet=${KUBE_VERSION}-00 kubeadm=${KUBE_VERSION}-00 kubectl=${KUBE_VERSION}-00
sudo apt-mark hold kubeadm kubelet kubectl

echo
echo "######## kubectl version ########"
echo
kubectl version --client

echo
echo "######## kubeadm version ########"
echo
kubeadm version

echo
echo "######## kubelet version ########"
echo
kubelet --version
echo
