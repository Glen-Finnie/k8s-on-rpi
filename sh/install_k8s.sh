#!/usr/bin/env bash

set -e

source test_fn.sh

source /etc/lsb-release
if [ "$DISTRIB_RELEASE" != "22.04" ]
then
    echo
    echo "########################################"
    echo "############### ERROR ##################"
    echo "########################################"
    echo
    echo "This script is intended for Ubuntu 22.04"
    echo "You're using: ${DISTRIB_DESCRIPTION}"
    exit 1
fi

MACHINE=$(uname -m)
if [ $MACHINE != "aarch64" ]
then
    echo
    echo "########################################"
    echo "############### ERROR ##################"
    echo "########################################"
    echo
    echo "This script is intended for 64 Ubuntu"
    echo "You're using: ${MACHINE}, i.e., 32 bit"
    exit 1
fi

sudo apt --yes install apt-transport-https ca-certificates curl gpg

# https://docs.cilium.io/en/stable/operations/system_requirements/#ubuntu-22-04-on-raspberry-pi
sudo apt --yes install linux-modules-extra-raspi

# Install NFS suport files
sudo apt --yes install nfs-common

# Enable Kernal overlay & br_netfilter modules required by containerd
# Add overlay & br_netfilter to k8s.conf file so module will load on
# restart.
add_overlay_and_br_netfilter_modules_function () {

# Add overlay & br_netfilter to k8s.conf file
    cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
    echo
    echo "# added overlay & br_netfilter modules to /etc/modules-load.d/k8s.conf #"

    # Load the overlay & br_netfilter modules
    sudo modprobe overlay
    sudo modprobe br_netfilter

    echo
    echo "# loading overlay & br_netfilter modules #"
}

### From https://kubernetes.io/docs/setup/production-environment/container-runtimes/#install-and-configure-prerequisites

### Enable Kernal overlay & br_netfilter modules required by containerd

if check_overlay_and_br_netfilter_modules_loaded_function
then

    echo
    echo "# overlay & br_netfilter modules loaded #"

else

    echo
    echo "# overlay & br_netfilter modules not loaded #"

    add_overlay_and_br_netfilter_modules_function

    if check_overlay_and_br_netfilter_modules_loaded_function
    then

        echo
        echo "# overlay & br_netfilter modules loaded #"

    else

        echo
        echo "#######################################################"
        echo "###################### ERROR ##########################"
        echo "#######################################################"
        echo "# Error overlay & br_netfilter modules failed to load #"
        echo
        exit 1
    fi
fi

add_net_configurations_function() {

   # sysctl params required by setup
   cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
EOF

   # Apply sysctl params
   sudo sysctl --system
}

# From https://kubernetes.io/docs/setup/production-environment/container-runtimes/#forwarding-ipv4-and-letting-iptables-see-bridged-traffic

# Forwarding IPv4 and letting iptables see bridged traffic
echo
echo "# Forwarding IPv4 and letting iptables see bridged traffic #"

if check_ip_forward_enabled_function && check_bridged_packets_sent_to_iptable_function
then

    echo
    echo "# sysctl net configurations set correctly #"

else

    echo
    echo "# sysctl net configurations not set correctly #"

    add_net_configurations_function

    if check_ip_forward_enabled_function && check_bridged_packets_sent_to_iptable_function
    then

        echo
        echo "# sysctl net configurations set correctly #"

    else

        echo
        echo "###############################################"
        echo "################# ERROR #######################"
        echo "###############################################"
        echo "# sysctl net configurations not set correctly #"
        echo
        exit 1
    fi
fi

# Disable swap
sudo swapoff -a
echo
echo "# Disabled swap #"

# Install containerd, runc
# From https://github.com/containerd/containerd/blob/main/docs/getting-started.md

echo
echo "# Starting install of containerd, runc #"
mkdir -p files

install_runc_function() {

    ## Install runc
    RUNC_VERSION=1.1.12
    wget -qP files https://github.com/opencontainers/runc/releases/download/v${RUNC_VERSION}/runc.arm64
    sudo install -m 755 files/runc.arm64 /usr/local/sbin/runc

    ## Mark runc so apt package manager doesn't overwrite 
    sudo apt-mark hold runc

    echo
    echo "######## runc version ########"
    echo
    runc --version
    echo
}

if check_runc_installed_function
then
    echo
    echo "##### runc already installed #####"
else
    echo
    echo "### runc not found, installing ###"

    install_runc_function

    if check_runc_installed_function
    then
        echo
        echo "##### runc installed #####"
    else

        echo
        echo "###############################################"
        echo "################# ERROR #######################"
        echo "###############################################"
        echo "############## runc not installed #############"
        echo
        exit 1
    fi
fi

install_containerd_function() {

    ## Install containerd
    CONTAINERD_VERSION=1.7.13
    wget -qP files https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-arm64.tar.gz
    sudo tar Cxzvf /usr/local files/containerd-${CONTAINERD_VERSION}-linux-arm64.tar.gz

    ## Mark containerd so apt package manager doesn't overwrite 
    sudo apt-mark hold containerd

    echo
    echo "######## containerd version ########"
    echo
    containerd --version
    echo
}

if check_containerd_installed_function
then
    echo
    echo "##### containerd already installed #####"
else
    echo
    echo "### containerd not found, installing ###"

    install_containerd_function

    if check_containerd_installed_function
    then
        echo
        echo "##### containerd installed #####"
    else

        echo
        echo "###############################################"
        echo "################# ERROR #######################"
        echo "###############################################"
        echo "########### containerd not installed ##########"
        echo
        exit 1
    fi
fi

install_containerd_service_file_function() {

    ## Load systemd containerd service file
    sudo mkdir -p /usr/local/lib/systemd/system
    sudo wget -qP /usr/local/lib/systemd/system https://raw.githubusercontent.com/containerd/containerd/main/containerd.service

    echo
    echo "Downloaded systemd containerd service file"
}

start_containerd_service_function() {

    sudo systemctl daemon-reload
    sudo systemctl enable --now containerd

    echo
    echo "Reloaded systemd daemon"
}

if check_containerd_service_running_function
then
    echo
    echo "##### containerd service running #####"
else
    echo
    echo "# containerd service not running #"
    echo "# checking service file present #"

    if check_containerd_service_file_function
    then
        echo
        echo "## containerd service file found ##"

        start_containerd_service_function

    else
        echo
        echo "# containerd service file not found #"

        install_containerd_service_file_function

        if check_containerd_service_file_function
        then
            echo
            echo "## containerd service file found ##"

            start_containerd_service_function
        else
            echo
            echo "###############################################"
            echo "################# ERROR #######################"
            echo "###############################################"
            echo "##### containerd service file not found #######"
            echo
            exit 1
        fi
    fi

    if check_containerd_service_running_function
    then
        echo
        echo "##### containerd service running #####"
    else
        echo
        echo "###############################################"
        echo "################# ERROR #######################"
        echo "###############################################"
        echo "####### containerd service not running ########"
        echo
        exit 1
    fi
fi

install_containerd_config_file_function() {

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
}

if check_containerd_config_file_function
then
    echo
    echo "##### containerd config.toml in present #####"
else
    echo
    echo "### containerd config.toml not found ###"

    install_containerd_config_file_function

    if check_containerd_config_file_function
    then
        echo
        echo "##### containerd config.toml in present #####"
    else

        echo
        echo "###############################################"
        echo "################# ERROR #######################"
        echo "###############################################"
        echo "####### containerd config.toml not found ######"
        echo
        exit 1
    fi
fi

install_kubeadm_kubelet_kubectl_function() {

    # install kubeadm kubelet kubectl

    ### https://kubernetes.io/blog/2023/08/15/pkgs-k8s-io-introduction/ describes the current Kubernetes package repository approach

    KUBE_MINOR_VERSION=1.29
    KUBE_PATCH_VERSION=2
    KUBE_REVISION=1.1
    KUBE_VERSION=${KUBE_MINOR_VERSION}.${KUBE_PATCH_VERSION}-${KUBE_REVISION}

    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v"${KUBE_MINOR_VERSION}"/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v${KUBE_MINOR_VERSION}/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

    sudo apt update
    sudo apt --yes install kubelet=${KUBE_VERSION} kubeadm=${KUBE_VERSION} kubectl=${KUBE_VERSION}
    sudo apt-mark hold kubeadm kubelet kubectl

    sudo apt-mark hold cri-tools kubernetes-cni
    # cri-tools (crictl & critest) and kubernetes-cni are dependencies for kubelet and kubeadm and will be installed along with kubeadm
}

if check_kubernetes_apt_repository_function
then
    echo
    echo "# kubeadm kubelet kubectl already installed #"
else
    install_kubeadm_kubelet_kubectl_function
fi

install_crictl_config_file_function() {

### Set the endpoint for crictl to containerd

    cat <<EOF | sudo tee /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
EOF

}

if check_crictl_config_file_function
then
    echo
    echo "# crictl.yaml file present #"
else
    echo
    echo "# crictl.yaml file not found #"

    install_crictl_config_file_function

    if check_crictl_config_file_function
    then
        echo
        echo "# crictl.yaml file present #"
    else

        echo
        echo "###############################################"
        echo "################# ERROR #######################"
        echo "###############################################"
        echo "########## crictl.yaml file not found #########"
        echo
        exit 1
    fi
fi

### Check containerd is configured to use the systemd cgroup driver
echo
echo "############ SystemdCgroup true ############"
echo "# The value below must SystemdCgroup: true #"
echo
sudo crictl info | grep SystemdCgroup
echo

# Set up auto complete and alias for kubectl
if ! grep -q 'source <(kubectl completion bash)' ~/.bashrc; then
    echo 'source <(kubectl completion bash)' >> ~/.bashrc
fi
if ! grep -q 'alias k=kubectl' ~/.bashrc; then
    echo 'alias k=kubectl' >> ~/.bashrc
fi
if ! grep -q 'complete -F __start_kubectl k' ~/.bashrc; then
    echo 'complete -F __start_kubectl k' >> ~/.bashrc
fi