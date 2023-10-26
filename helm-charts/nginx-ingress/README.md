# Nginx Ingress

## Introduction

This chart installs NGINX Ingress Controller for IBM Cloud Private in your cluster.

## Chart Details

This chart:
* Installs NGINX Ingress Controller.
* Adds a deployment to running NGINX Ingress Controller pod on proxy nodes.
* Adds a service default-http-backend.
* Adds a configmap nginx-ingress-controller.

## Prerequisites

* Installing a PodDisruptionBudget
* Kubernetes v1.11+
* OpenShift 3.11+
* Tiller v2.12.3+

### PodSecurityPolicy Requirements

The predefined PodSecurityPolicy name: [`ibm-privileged-psp`](https://ibm.biz/cpkspec-psp) has been verified for this chart, if your target namespace is bound to this PodSecurityPolicy you can proceed to install the chart.

Custom PodSecurityPolicy definition:

```yaml
apiVersion: extensions/v1beta1
kind: PodSecurityPolicy
metadata:
  annotations:
    kubernetes.io/description: "This policy grants access to all privileged
      host features and allows a pod to run with any
      UID and GID and any volume.
      WARNING:  This policy is the least restrictive and
      should only used for cluster administration.
      Use with caution."
    seccomp.security.alpha.kubernetes.io/allowedProfileNames: '*'
  name: ibm-privileged-psp
spec:
  allowPrivilegeEscalation: true
  allowedCapabilities:
    - '*'
  allowedUnsafeSysctls:
    - '*'
  fsGroup:
    rule: RunAsAny
  hostIPC: true
  hostNetwork: true
  hostPID: true
  hostPorts:
    - max: 65535
      min: 0
  privileged: true
  runAsUser:
    rule: RunAsAny
  seLinux:
    rule: RunAsAny
  supplementalGroups:
    rule: RunAsAny
  volumes:
    - '*'
```

### Red Hat OpenShift SecurityContextConstraints Requirements

The predefined SecurityContextConstraints name: [`ibm-privileged-scc`](https://ibm.biz/cpkspec-scc) has been verified for this chart, if your target namespace is bound to this SecurityContextConstraints resource you can proceed to install the chart.

Custom SecurityContextConstraints definition:

```yaml
apiVersion: security.openshift.io/v1
  kind: SecurityContextConstraints
  metadata:
    annotations:
      kubernetes.io/description: "This policy grants access to all privileged
        host features and allows a pod to run with any
        UID and GID and any volume.
        WARNING:  This policy is the least restrictive and
        should only be used for cluster administration.
        Use with caution."
      cloudpak.ibm.com/version: "1.1.0"
    name: ibm-privileged-scc
  allowHostDirVolumePlugin: true
  allowHostIPC: true
  allowHostNetwork: true
  allowHostPID: true
  allowHostPorts: true
  allowPrivilegedContainer: true
  allowPrivilegeEscalation: true
  allowedCapabilities:
  - '*'
  allowedFlexVolumes: []
  allowedUnsafeSysctls:
  - '*'
  defaultAddCapabilities: []
  defaultAllowPrivilegeEscalation: true
  forbiddenSysctls: []
  fsGroup:
    type: RunAsAny
  readOnlyRootFilesystem: false
  requiredDropCapabilities: []
  runAsUser:
    type: RunAsAny
  seccompProfiles:
  - '*'
  # This can be customized for your host machine
  seLinuxContext:
    type: RunAsAny
  # seLinuxOptions:
  #   level:
  #   user:
  #   role:
  #   type:
  supplementalGroups:
    type: RunAsAny
  volumes:
  - '*'
```

## Resources Required

* cpu: 50m
* memory: 256Mi

## Installing the Chart

```bash
helm install --namespace kube-system --name nginx-ingress nginx-ingress --tls
```

## Configuration

The following table lists the configurable parameters of the `ICP Management Ingress` chart and their default values.

| Parameter                                       | Description                                                    | Default                         |
|-------------------------------------------------|----------------------------------------------------------------|---------------------------------|
| ingress.name                                    | NGINX Ingress Controller deployment name                       | nginx-ingress-controller        |
| ingress.hostNetwork                             | using host network                                             | false                           |
| ingress.hostPort                                | exposing container port as host port                           | true                            |
| ingress.httpPort                                | Listening http port of nginx backend                           | 80                            |
| ingress.httpsPort                               | Listening https port of nginx backend                          | 443                            |
| ingress.image.repository                        | NGINX Ingress Controller image to use for this deployment      | ibmcom/nginx-ingress-controller |
| ingress.image.tag                               | NGINX Ingress Controller image tag to use for this deployment  | 0.23.4                          |
| ingress.image.pullPolicy                        | NGINX Ingress Controller image pull policy                     | IfNotPresent                    |
| ingress.resources.requests.cpu                  | cpu request to run this deployment                             | 50m                             |
| ingress.resources.requests.memory               | memory request to run this deployment                          | 256Mi                           |
| ingress.extraArgs                               | setting extra command line args                                | {}                              |
| ingress.config.disable-access-log               | NGINX Ingress Controller configmap setting of disable-access-log             | true              |
| ingress.config.keep-alive-requests              | NGINX Ingress Controller configmap setting of keep-alive-requests            | 1000             |
| ingress.config.upstream-keepalive-connections   | NGINX Ingress Controller configmap setting of upstream-keepalive-connections | 64                |
| ingress.config.server-tokens                    | NGINX Ingress Controller configmap setting of server-tokens                  | false             |
| ingress.config.ssl-ciphers                      | NGINX Ingress Controller configmap setting of ssl-ciphers      | ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256 |
| ingress.annotations                             | NGINX Ingress Controller annotations settings                  | {}                              |
| ingress.nodeSelector                            | nodeSelector of NGINX Ingress Controller deployment            | {}                              |
| ingress.tolerations                             | tolerations of NGINX Ingress Controller deployment             | key: "dedicated", operator: "Exists", effect: "NoSchedule", key: "CriticalAddonsOnly", operator: "Exists" |
| defaultBackend.name                             | defaultBackend deployment name                                 | default-http-backend            |
| defaultBackend.replicaCount                     | replicaCount of defaultBackend deployment                      | 1                               |
| defaultBackend.image.repository                 | defaultBackend image to use for this deployment                | ibmcom/default-http-backend     |
| defaultBackend.image.tag                        | defaultBackend image tag to use for this deployment            | 1.5.2                           |
| defaultBackend.image.pullPolicy                 | defaultBackend image pull policy                               | IfNotPresent                    |
| defaultBackend.extraArgs                        | setting extra command line args                                | {}                              |
| defaultBackend.resources.requests.cpu           | cpu request to run this deployment                             | 20m                             |
| defaultBackend.resources.requests.memory        | memory request to run this deployment                          | 64Mi                            |
| defaultBackend.nodeSelector                     | nodeSelector of defaultBackend deployment                      | {}                              |
| defaultBackend.tolerations                      | tolerations of defaultBackend deployment                       | key: "dedicated", operator: "Exists", effect: "NoSchedule", key: "CriticalAddonsOnly", operator: "Exists" |
| init.image.repository                           | init image to use for this deployment                          | ibmcom/icp-initcontainer        |
| init.image.tag                                  | init image tag to use for this deployment                      | 1.0.0-build.1                   |
| init.image.pullPolicy                           | init image pull policy                                         | IfNotPresent                    |
| fips_enabled                                    | enable FIPS mode                                               | false                           |

## Limitations

* Works on x86, ppc64le and s390x platform.
* Only users with privileged podsecuritypolicies can install this chart.
