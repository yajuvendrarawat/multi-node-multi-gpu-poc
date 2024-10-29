# Deploy Big LLMs with Multi-Worker and Multi-GPUs

Repo for PoC multi-node with multi-gpu

### Guide

* Install NFS Operator

```md
bash utils/nfs-operator.sh
```

* Install RHOAI and other operators

```md
kubectl apply -k 1-rhoai-operators/overlays/
```

* Install RHOAI, NFD, NFS and NVIDIA GPU Instances 

```md
kubectl apply -k 2-rhoai-instances/overlays/
```

* Deploy the prerequisites for the PoC including the Model

```md
kubectl apply -k 3-demo-prep/
```