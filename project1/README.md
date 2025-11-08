# azure-kubernetes-service

## create-aks.sh
chmod +x create-aks.sh
./create-aks.sh

## 01-namespace.yaml
```bash
kubectl apply -f namespace.yaml
kubectl get namespaces
kubectl describe namespace demo-namespace
```
## 02-pod.yaml

| Type                | Resource  | Value                                                  | Meaning |
| ------------------- | --------- | ------------------------------------------------------ | ------- |
| **requests.memory** | `"64Mi"`  | The container is guaranteed at least **64 MB of RAM**. |         |
| **requests.cpu**    | `"250m"`  | The container is guaranteed **0.25 CPU cores**.        |         |
| **limits.memory**   | `"128Mi"` | The container cannot use more than **128 MB of RAM**.  |         |
| **limits.cpu**      | `"500m"`  | The container cannot use more than **0.5 CPU cores**.  |         |

So, Kubernetes will schedule your pod only on nodes that have at least 64Mi and 250m CPU available, and if your container tries to use more than 128Mi memory or 500m CPU, the kernel (via cgroups) will throttle or evict it.
```bash
kubectl apply -f 02-pod.yaml
kubectl get pods -n demo-namespace
kubectl describe pod mypod -n demo-namespace
kubectl logs mypod -n demo-namespace
```
## 03-multi-container.yaml
Creates a Pod named multi-container in the namespace demo-namespace.
Runs two containers inside the same Pod:
nginx → serves as a lightweight web server.
redis → acts as a key-value store (running a sleep loop here so it stays alive).

command: ["sleep", "1000"]
The redis:latest container starts the Redis server (redis-server) immediately.
But by using command: ["sleep", "1000"], you’re replacing that startup command with a simple sleep command.
So effectively, when the Pod runs:
The Redis container will just sleep (do nothing) for 1000 seconds (≈16.6 minutes).
It will not start the Redis server process.
```bash
kubectl get pods -n demo-namespace
kubectl describe pod multi-container -n demo-namespace
```
To open a shell inside either container:
```bash
kubectl exec -it multi-container -n demo-namespace -c nginx -- /bin/bash
kubectl exec -it multi-container -n demo-namespace -c redis -- /bin/bash
```
## 04-multi-container-redis.yaml
Nginx runs as a web server.
Redis runs as an in-memory database.
Both share the same network namespace (so Nginx can reach Redis via localhost:6379).

Both containers run inside the same Pod, so they share:
The same localhost network (127.0.0.1)
The same storage volumes (if you add any)
Hence Nginx can access Redis directly at:
REDIS_HOST=localhost
REDIS_PORT=6379
Redis starts normally — no sleep command here.
Nginx runs on port 80, Redis on 6379.

```bash
kubectl apply -f 04-multi-container-redis.yaml
kubectl get pods -n demo-namespace
kubectl describe pod nginx-redis-pod -n demo-namespace
kubectl exec -it nginx-redis-pod -n demo-namespace -c redis -- redis-cli ping
# Should output: PONG
```

## 05-annotations.yaml
```bash
kubectl apply -f 05-annotations.yaml
kubectl describe pod annotations | grep -A 5 "Annotations"
```
Output:
Annotations:      description: This pod is created to demonstrate pod annotations
                  jenkins: https://jenkins.com/build/job/roboshop-catalouge/3
Status:           Running
IP:               10.244.1.121
IPs:
  IP:  10.244.1.121

## 07-env.yaml
```bash
kubectl exec -it env-demo-pod -- /bin/bash
echo $COURSE --> KUBERNETES
echo $PLATFORM --> AZURE
```
## 08-config-map.yaml
```bash
kubectl apply -f 08-config-map.yaml
kubectl get configmap my-config-map -o yaml
kubectl exec -it configmap-demo -- /bin/bash
env | grep CLOUD --> CLOUD=azure
env | grep RESOURCE --> RESOURCE=kubernetes
```
## 10-secret.yaml

# Create the secret and pod
```bash
kubectl apply -f 10-secret.yaml

# View the decoded secret value
kubectl get secret mysecret -o jsonpath='{.data.username}' | base64 --decode; echo --> kubernetesuser
kubectl get secret mysecret -o jsonpath='{.data.password}' | base64 --decode; echo --> P@ssword123

# Check pod environment variables (from inside the container)
kubectl exec -it secret-demo -- /bin/bash
env | grep username --> username=kubernetesuser
env | grep password --> password=P@ssword123
```

## 12-service.yaml
```bash
kubectl apply -f 12-service.yaml
kubectl get svc
```
The selector tells the Service to find Pods with matching labels.
The Service type defaults to ClusterIP (internal only).
It forwards requests on port 80 → container’s port 80.
The Pod’s labels match the Service’s selector, so traffic will be routed correctly.
image: nginx runs a simple Nginx web server.

## 13-service-np.yaml
```bash
kubectl apply -f 13-service-np.yaml
kubectl get svc
```
NAME       TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
nginx-np     NodePort    10.0.144.207   <none>        80:31276/TCP   43s
Type: NodePort (makes it accessible outside the cluster via a node’s IP and a high port).
NodePort will be automatically assigned (in the 30000–32767 range) unless specified.
NodePort works only from within the VNet.

## 14-service-lb.yaml
```bash
kubectl apply -f 14-service-lb.yaml
kubectl get svc
```
NAME       TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
nginx-lb     LoadBalancer   10.0.71.108    13.71.60.23   80:32134/TCP   98s

If your AKS cluster is public:
Azure automatically provisions a public IP for the service.
Open <EXTERNAL-IP> in a browser — you’ll see the default NGINX welcome page.

If your AKS cluster is private:
The LoadBalancer’s EXTERNAL-IP will be a private IP from your AKS subnet (e.g., 10.x.x.x).
You can access it only from within the same VNet (for example, via a VM, Bastion host, or debug pod).

## 15-replicaset.yaml
```bash
kubectl apply -f 15-replicaset.yaml
kubectl get rs
kubectl get pods -l app=my-app
```
NAME                  READY   STATUS    RESTARTS   AGE
my-replicaset-gvhlb   1/1     Running   0          2m42s
my-replicaset-xslml   1/1     Running   0          2m42s

## 16-deployment.yaml
```bash
kubectl apply -f 16-deployment.yaml
kubectl get deployments
kubectl set image deployment/my-deployment my-container=nginx:1.21
kubectl rollout status deployment/my-deployment
kubectl rollout undo deployment/my-deployment
```
This manifest creates a Deployment named my-deployment that manages 2 replicas (pods) of an NGINX container.
Purpose: Automatically ensures 2 identical pods are always running.
Use case: For stateless applications (like web frontends) where pod identity doesn’t matter.
Controller: Deployment (which manages ReplicaSets).

It ensures availability — never deletes all Pods at once (default maxUnavailable=25%).
Deployment is a higher-level controller that manages ReplicaSets automatically.
It provides rolling updates, rollbacks, and version tracking, unlike a plain ReplicaSet.

Rolling Updates
deployment "my-deployment" successfully rolled out
During the rollout:
Kubernetes gradually replaces old Pods (nginx:1.19) with new ones (nginx:1.21).

Rollback
kubectl rollout history deployment/my-deployment
Suppose the new image is broken — you can revert easily:
This automatically:
Restores the Deployment to the previous ReplicaSet.
Deletes the bad Pods and replaces them with the working ones.

Version Tracking
kubectl get rs
NAME                       DESIRED   CURRENT   READY   AGE
my-deployment-5c7b5d4b49   0         0         0       15m   # old (nginx:1.19)
my-deployment-7d6b8f65b6   2         2         2       2m    # new (nginx:1.21)

You can pause and resume ongoing rollouts for controlled deployments:
```bash
kubectl rollout pause deployment/my-deployment
kubectl rollout resume deployment/my-deployment
```

## 17-statefulset.yaml
```bash
kubectl apply -f 17-statefulset.yaml
kubectl get pods -l purpose=statefulset
kubectl get svc
kubectl get pvc
```
pods
nginx-statefulset-0
nginx-statefulset-1
nginx-statefulset-2

svc
NAME                 TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
nginx-svc-headless   ClusterIP      None           <none>        80/TCP         116s
nginx-svc-normal     ClusterIP      10.0.10.124    <none>        80/TCP         116s
nginx-svc-lb         LoadBalancer   10.0.169.79    4.187.178.232   80:32505/TCP   31s

pvc
NAME                      STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
www-nginx-statefulset-0   Bound    pvc-71f7d94c-473f-4194-b237-61920c5e3bcc   1Gi        RWO            default        <unset>                 3m54s
www-nginx-statefulset-1   Bound    pvc-d72f4b0c-0265-456e-82f1-81e0a8e9410d   1Gi        RWO            default        <unset>                 3m28s
www-nginx-statefulset-2   Bound    pvc-4b24b95a-e4ef-47a8-922b-31741b5d7457   1Gi        RWO            default        <unset>                 3m6s
```bash
kubectl exec -it nginx-statefulset-0 -- bash
echo "Hello from Pod 0" > /usr/share/nginx/html/index.html
exit
kubectl delete pod nginx-statefulset-0
kubectl exec -it nginx-statefulset-0 -- cat /usr/share/nginx/html/index.html
```
Hello from NGINX StatefulSet Pod nginx-statefulset-2

This manifest defines:
A headless Service (nginx-svc-headless) → gives each pod a stable DNS identity (e.g., nginx-statefulset-0.nginx-svc-headless).
A normal Service (nginx-svc-normal) → load-balances traffic across the pods.
A StatefulSet (nginx-statefulset) → creates 3 NGINX pods (nginx-statefulset-0, -1, -2), each with persistent storage via a PersistentVolumeClaim.
Purpose: Used for stateful applications (like databases or services that need stable network names and persistent storage).

Added initcontainers in spec of statefulset
Now open http://<EXTERNAL-IP> — you should see:
Hello from Pod 0

# 19-liveness-readiness.yaml
```bash
kubectl apply -f 19-liveness-readiness.yaml
kubectl get pods
kubectl exec -it live-readiness -- rm -rf /usr/share/nginx/html/index.html

```
Liveness probe:
Initial delay: 30 seconds
Period: Every 10 seconds
If the container doesn’t respond with HTTP 200 within 1 second, it’s considered unhealthy.
Kubernetes will restart the container if it fails the liveness check.

Readiness probe:
Initial delay: 40 seconds
Period: Every 3 seconds
Determines when the container is ready to accept traffic.
If the container doesn’t respond with HTTP 200 within 1 second, it’s considered not ready.
Kubernetes will stop sending traffic to the pod until it passes the readiness check.  

# 20-network-policy.yaml
```bash
kubectl apply -f 20-network-policy.yaml
kubectl get networkpolicy
```
Deploy Simple Test Pods
kubectl run frontend --image=busybox --labels="role=frontend" --restart=Never -- sleep 3600
kubectl run backend --image=nginx --labels="role=backend" --port=80 --restart=Never

Create a Service for the backend
kubectl expose pod backend --port=80 --target-port=80 --name=backend
Test Connectivity
From frontend to backend (should succeed):
```bash
kubectl exec -it frontend -- wget --spider http://backend
Connecting to backend (10.0.188.36:80)
remote file exists
```

From another pod without role=frontend (should fail):
```bash
kubectl run testpod --image=busybox --restart=Never -- sleep 3600
kubectl exec -it testpod -- wget --spider http://backend
```

Make sure below settings are there while creating AKS cluster
network-plugin: azure network-policy: calico 

# 11-