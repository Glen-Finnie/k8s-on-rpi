# K8s on RPI

Base scripts for installing Kubernetes version 1.29.0 on Raspberry Pi 4 running Ubuntu LTS.

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
sudo sync; sudo reboot
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

### Cilium CNI (Container Network Interface)

Install Cilium networking

```sh
./install_cilium.sh
```

### Check The Status

Look at the pods, note the CoreDNS pods will be in *Pending* state until Cilium is fully installed and running.

```sh

$ kubectl get pods -A
NAMESPACE     NAME                               READY   STATUS              RESTARTS   AGE
kube-system   cilium-g7mx9                       0/1     Init:0/6            0          74s
kube-system   cilium-operator-6b8f454664-8dsmw   0/1     ContainerCreating   0          74s
kube-system   coredns-76f75df574-bs7ch           0/1     Pending             0          4m45s
kube-system   coredns-76f75df574-m97lc           0/1     Pending             0          4m45s
kube-system   etcd-k8s02                         1/1     Running             0          5m6s
kube-system   kube-apiserver-k8s02               1/1     Running             0          5m3s
kube-system   kube-controller-manager-k8s02      1/1     Running             0          5m3s
kube-system   kube-proxy-dsfj5                   1/1     Running             0          4m45s
kube-system   kube-scheduler-k8s02               1/1     Running             0          5m3s
```

Wait a few minutes until Cilium running.

```sh
$ kubectl get pods -A
NAMESPACE     NAME                               READY   STATUS    RESTARTS        AGE
kube-system   cilium-g7mx9                       1/1     Running   0               4m54s
kube-system   cilium-operator-6b8f454664-8dsmw   1/1     Running   0               4m54s
kube-system   coredns-76f75df574-bs7ch           1/1     Running   0               8m25s
kube-system   coredns-76f75df574-m97lc           1/1     Running   0               8m25s
kube-system   etcd-k8s02                         1/1     Running   0               8m46s
kube-system   kube-apiserver-k8s02               1/1     Running   0               8m43s
kube-system   kube-controller-manager-k8s02      1/1     Running   1 (3m37s ago)   8m43s
kube-system   kube-proxy-dsfj5                   1/1     Running   0               8m25s
kube-system   kube-scheduler-k8s02               1/1     Running   1 (3m37s ago)   8m43s
```

containerd service

```sh
sudo systemctl status containerd.service
```

kubelet service

```sh
sudo systemctl status kubelet.service
```

```sh
$ cilium status
    /¯¯\
 /¯¯\__/¯¯\    Cilium:             OK
 \__/¯¯\__/    Operator:           OK
 /¯¯\__/¯¯\    Envoy DaemonSet:    disabled (using embedded mode)
 \__/¯¯\__/    Hubble Relay:       disabled
    \__/       ClusterMesh:        disabled

DaemonSet              cilium             Desired: 1, Ready: 1/1, Available: 1/1
Deployment             cilium-operator    Desired: 1, Ready: 1/1, Available: 1/1
Containers:            cilium             Running: 1
                       cilium-operator    Running: 1
Cluster Pods:          2/2 managed by Cilium
Helm chart version:    1.14.5
Image versions         cilium-operator    quay.io/cilium/operator-generic:v1.14.5@sha256:303f9076bdc73b3fc32aaedee64a14f6f44c8bb08ee9e3956d443021103ebe7a: 1
                       cilium             quay.io/cilium/cilium:v1.14.5@sha256:d3b287029755b6a47dee01420e2ea469469f1b174a2089c10af7e5e9289ef05b: 1
```

### Initialize Worker Node
