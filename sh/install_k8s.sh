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
echo 'source <(kubectl completion bash)' >> ~/.bashrc
echo 'alias k=kubectl' >> ~/.bashrc
echo 'complete -F __start_kubectl k' >> ~/.bashrc

### Check ip_forward is enabled
echo
echo "#####################################"
echo "######## net.ipv4.ip_forward ########"
echo "# The value below must be 1 (not 0) #"
sysctl net.ipv4.ip_forward

### Disable swap
swapoff -a

### From https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/

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

### Install containerd
CONTAINERD_VERSION=1.6.12
mkdir files
wget -qP files https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-arm64.tar.gz
sudo tar Cxzvf /usr/local files/containerd-${CONTAINERD_VERSION}-linux-arm64.tar.gz

echo
echo "######## containerd version ########"
echo
containerd --version
echo

sudo mkdir -p /usr/local/lib/systemd/system
sudo wget -qP /usr/local/lib/systemd/system https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
sudo systemctl daemon-reload
sudo systemctl enable --now containerd

### Install runc
RUNC_VERSION=1.1.4
wget -qP files https://github.com/opencontainers/runc/releases/download/v${RUNC_VERSION}/runc.arm64
sudo install -m 755 files/runc.arm64 /usr/local/sbin/runc

### Install CNI plugins
CNI_VERSION=1.1.1
wget -qP files https://github.com/containernetworking/plugins/releases/download/v${CNI_VERSION}/cni-plugins-linux-arm64-v${CNI_VERSION}.tgz
sudo mkdir -p /opt/cni/bin
sudo tar Cxzvf /opt/cni/bin files/cni-plugins-linux-arm64-v${CNI_VERSION}.tgz

### Set the endpoint for crictl to containerd
cat <<EOF | sudo tee /etc/crictl.yaml
runtime-endpoint: unix:///var/run/containerd/containerd.sock
image-endpoint: unix:///var/run/containerd/containerd.sock
timeout: 10
EOF

### Create the containerd config file
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null

### Modify containerd config file to use systemd

### [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
###   ...
###   [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
###     SystemdCgroup = true
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
sudo systemctl restart containerd

echo
echo "######## SystemdCgroup true ########"
echo
sudo crictl info | grep SystemdCgroup
echo

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

### Set up auto complete and alias for kubectl
echo 'source <(kubectl completion bash)' >> ~/.bashrc
echo 'alias k=kubectl' >> ~/.bashrc
echo 'complete -F __start_kubectl k' >> ~/.bashrc
