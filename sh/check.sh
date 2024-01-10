#!/usr/bin/env bash

set -e

# Check the overlay module is loaded
echo
echo "################ overlay ###################"
echo "# if value is displayed then module loaded #"
echo
lsmod | grep overlay
echo

# Check the br_netfilter module is loaded
echo
echo "############## br_netfilter ################"
echo "# if value is displayed then module loaded #"
echo
lsmod | grep br_netfilter
echo

### Check ip_forward is enabled
echo
echo "#####################################"
echo "######## net.ipv4.ip_forward ########"
echo "# The value below must be 1 (not 0) #"
echo
sysctl net.ipv4.ip_forward
echo

### Check whether packets crossing a bridge are sent to iptables for processing enabled
echo
echo "######################################"
echo "# net.bridge.bridge-nf-call-iptables #"
echo "# The value below must be 1 (not 0) ##"
echo
sysctl net.bridge.bridge-nf-call-iptables
echo

### Check whether IP6 packets crossing a bridge are sent to iptables for processing enabled
echo
echo "#######################################"
echo "# net.bridge.bridge-nf-call-ip6tables #"
echo "## The value below must be 1 (not 0) ##"
echo
sysctl net.bridge.bridge-nf-call-ip6tables
echo

echo
echo "######## containerd version ########"
echo
containerd --version
echo

echo
echo "######## runc version ########"
echo
runc --version
echo

echo
echo "######## runc crictl ########"
echo
crictl --version
echo

### Check containerd is configured to use the systemd cgroup driver
echo
echo "############ SystemdCgroup true ############"
echo "# The value below must SystemdCgroup: true #"
echo
sudo crictl info | grep SystemdCgroup
echo

echo
echo "######## kubectl version ########"
echo
kubectl version --client
echo

echo
echo "######## kubeadm version ########"
echo
kubeadm version
echo

echo
echo "######## kubelet version ########"
echo
kubelet --version
echo
