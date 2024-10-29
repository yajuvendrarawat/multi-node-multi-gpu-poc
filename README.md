# Deploy Big LLMs with Multi-Worker and Multi-GPUs

Repo for PoC multi-node with multi-gpu

### Guide

* Export Variables

```md
DEMO_NAMESPACE="demo-multi-node-multi-gpu"
MODEL_NAME="vllm-llama3-8b"
```

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

* Deploy Custom CRD and vLLM Multi Node Serving Runtime Template

```md
kubectl apply -k 4-demo-deploy-is-sr
oc process vllm-multinode-runtime-template -n $DEMO_NAMESPACE | kubectl apply -n $DEMO_NAMESPACE -f -  
```

### Check and Validate the Model deployed in Multi-Node with Multi-GPUs

* Check the GPU resource status

```md
podName=$(oc get pod -l app=isvc.$MODEL_NAME-predictor --no-headers|cut -d' ' -f1)
workerPodName=$(kubectl get pod -l app=isvc.$MODEL_NAME-predictor-worker --no-headers|cut -d' ' -f1)

oc wait --for=condition=ready pod/${podName} --timeout=300s
```

* You can check the logs for both the head and worker pods:

    - **Head Node**

![head pod](./docs/image1.png)

![head pod](./docs/image2.png)

    - **Worker Node**

![worker pod](./docs/image3.png)

*  Check the GPU memory size for both the head and worker pods

```md
echo "### HEAD NODE GPU Memory Size"
kubectl exec $podName -- nvidia-smi
echo "### Worker NODE GPU Memory Size"
kubectl exec $workerPodName -- nvidia-smi
```

* Verify the status of your InferenceService, run the following command:

```md
oc wait --for=condition=ready pod/${podName} -n $DEMO_NAMESPACE --timeout=300s
export isvc_url=$(oc get route |grep $MODEL_NAME-vllm-multinode| awk '{print $2}')

* Send a RESTful request to the LLM deployed in Multi-Node Multi-GPU:

curl http://$isvc_url/v1/completions \
       -H "Content-Type: application/json" \
       -d '{
            "model": "$MODEL_NAME",
            "prompt": "At what temperature does Nitrogen boil?",
            "max_tokens": 100,
            "temperature": 0
        }'

```