# Reset the Cluster

kubectl delete --all deployments -A

kubectl delete --all namespaces

kubectl delete --all pods -A

## Remove the nodes

On the control plane list the nodes:

```sh
kubectl get nodes
```

Select the node to be removed and drain, e.g., selecting node k8s02:

```sh
kubectl drain k8s02 --delete-emptydir-data --force --ignore-daemonsets
```

The selected node will be "drain" as in the pods that can be moved will be migrated to other nodes.

When the drain command has completed, reset the worker node (e.g., k8s02) by issuing the following command on the node:

```sh
sudo kubeadm reset
```

The reset command will remove the node from the control plane, now on the control plane delete the node:

On the control plane drain:

```sh
kubectl delete node k8s02
```

Once all the worker nodes have been delete on the control plane

```sh
sudo kubeadm reset
```

On the **control-plane node only** use the kubeadm tool to initialise the cluster. Here the default values are used except the pod network (as described above) is used.

```sh
sudo kubeadm init --pod-network-cidr=172.16.0.0/18
```

```sh
cilium install --version 1.14.6
```
