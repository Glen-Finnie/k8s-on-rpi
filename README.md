# k8s-on-rpi

Base scripts for installing Kubernetes version 1.26.0 on Raspberry Pi 4 running Ubuntu LTS.

Scripts are designed to run on Ubuntu 22.04 (tested on Ubuntu Server 22.04.3 LTS 64-bit).

Prerequisite components

* containerd version v1.7.11
* runc version 1.1.11

## Install

On a new install of Ubuntu 22.04, clone the Git repository

```sh
git clone https://github.com/Glen-Finnie/k8s-on-rpi.git
```

Update the Ubuntu packages.

```sh
cd k8s-on-rpi
./update.sh
```

After the Ubuntu packages have been updated reboot the server.

```sh
sudo sync;sudo reboot
```

Once the server has come back up, install Kubernetes and the required prerequisite components.

```sh
cd k8s-on-rpi
./install_k8s.sh
```

## Initialize the Kubernetes Cluster

### Initialize Control-Plane Node

On the control-plane node only

```sh
sudo kubeadm init --pod-network-cidr=172.16.0.0/18
```

Execute the scripts at the end of the output to start the cluster as a regular user

```sh
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Check the status of the kubelet service

```sh
sudo systemctl status kubelet.service
```

As no CNI (Container Network Interface) plugin is installed, then "Container runtime network not ready" error messages will be displayed.

### Initialize Worker Node
