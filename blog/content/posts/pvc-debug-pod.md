---
title: "PVC Debug Pod"
date: 2024-03-04T22:05:41-08:00
tags:
  - k8s

---
I've been annoyed sufficiently-often by the fact that there is no single `kubectl` command to "_create a pod, and attach a PVC to it_" that I threw together the following script:
<!--more-->
```bash
#!/bin/bash

set -ex

# This script assumes the existence and correct configuration of `kubectl` and `fzf`.
# TODO - cool feature would be to grab namespaces with `kubectl get ns` and pipe through `fzf` to select - but, 99% of the time, this'll just be for the current namespace anyway

PVC_TO_MOUNT=$(kubectl get pvc --no-headers | awk '{print $1}' | fzf)
POD_CREATE_OUTPUT=$(cat <<EOF | kubectl create -f -
apiVersion: v1
kind: Pod
metadata:
  generateName: debug-pod-
spec:
  volumes:
    - name: pvc
      persistentVolumeClaim:
        claimName: $PVC_TO_MOUNT
  containers:
    - name: debug-container
      image: ubuntu
      command: [ "/bin/bash", "-c", "--" ]
      args: [ "while true; do sleep 30; done;" ]
      volumeMounts:
        - mountPath: "/mnt/pvc"
          name: pvc
EOF
)
POD_NAME=$(echo $POD_CREATE_OUTPUT | awk '{print $1}')
kubectl wait --for=condition=Ready $POD_NAME
kubectl exec -it $POD_NAME /bin/bash

```

While researching it, I did find out that [Ephemeral Containers](https://kubernetes.io/docs/concepts/workloads/pods/ephemeral-containers/) are now a thing - but, given that they also don't appear to allow a PVC-mount in their `kubectl`-creation, I suspect you'd still have to create via `cat <<EOF | kubectl create`[^why-create] anyway.

[^why-create]: Why `create` and not `apply`? Because you can't use `generateName` with `apply`, and if I accidentally forget to tear down an pre-existing debug-pod I'd rather not be interrupted in what I'm doing. Arguably, though, that would be a good reminder to clean up after myself.
