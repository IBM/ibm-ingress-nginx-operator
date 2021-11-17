# ibm-ingress-nginx-operator

> **Important:** Do not install this operator directly. Only install this operator using the IBM Common Services Operator. For more information about installing this operator and other Common Services operators, see [Installer documentation](http://ibm.biz/cpcs_opinstall). If you are using this operator as part of an IBM Cloud Pak, see the documentation for that IBM Cloud Pak to learn more about how to install and use the operator service. For more information about IBM Cloud Paks, see [IBM Cloud Paks that use Common Services](http://ibm.biz/cpcs_cloudpaks).

The IBM Ingress Nginx Repo operator provides a Helm chart repository for storing and supplying IBM and local charts.

The Ingress Nginx Operator installs the following components:
- The Ingress Nginx service (controller)
- A deployment to running Ingress Nginx controller pod
- A service default-http-backend
- A configmap nginx-ingress-controller
- A service account nginx-ingress
- A route cp-proxy

For more information about the available IBM Cloud Platform Common Services, see the [IBM Knowledge Center](http://ibm.biz/cpcsdocs).

## Supported platforms

Red Hat OpenShift Container Platform 4.3 or newer installed on one of the following platforms:

- Linux x86_64
- Linux on Power (ppc64le)
- Linux on IBM Z and LinuxONE

## Operator versions

- 1.1.0
- 1.2.0
- 1.2.1
- 1.2.2
- 1.3.0
- 1.3.1
- 1.4.0
- 1.4.1
- 1.5.0
- 1.6.0
- 1.7.0
- 1.7.1
- 1.8.0
- 1.9.0
- 1.9.1
- 1.10.0
- 1.11.0

## Prerequisites

Before you install this operator, you need to first install the operator dependencies and prerequisites:

- For the list of operator dependencies, see the IBM Knowledge Center [Common Services dependencies documentation](http://ibm.biz/cpcs_opdependencies).

- For the list of prerequisites for installing the operator, see the IBM Knowledge Center [Preparing to install services documentation](http://ibm.biz/cpcs_opinstprereq).

## Documentation

To install the operator with the IBM Common Services Operator follow the the installation and configuration instructions within the IBM Knowledge Center.

- If you are using the operator as part of an IBM Cloud Pak, see the documentation for that IBM Cloud Pak. For a list of IBM Cloud Paks, see [IBM Cloud Paks that use Common Services](http://ibm.biz/cpcs_cloudpaks).
- If you are using the operator with an IBM Containerized Software, see the IBM Cloud Platform Common Services Knowledge Center [Installer documentation](http://ibm.biz/cpcs_opinstall).

## SecurityContextConstraints Requirements

The Ingress Nginx service requires running with the OpenShift Container Platform 4.3 default privileged Security Context Constraints (SCCs).

For more information about the OpenShift Container Platform Security Context Constraints, see [Managing Security Context Constraints](https://docs.openshift.com/container-platform/4.3/authentication/managing-security-context-constraints.html).

## Developer guide

If, as a developer, you are looking to build and test this operator to try out and learn more about the operator and its capabilities, you can use the following developer guide. This guide provides commands for a quick install and initial validation for running the operator.

> **Important:** The following developer guide is provided as-is and only for trial and education purposes. IBM and IBM Support does not provide any support for the usage of the operator with this developer guide. For the official supported install and usage guide for the operator, see the the IBM Knowledge Center documentation for your IBM Cloud Pak or for IBM Cloud Platform Common Services.

### Quick start guide

Use the following quick start commands for building and testing the operator:

#### Cloning the operator repository

```bash
# git clone https://github.com/IBM/ibm-ingress-nginx-operator.git
# cd ibm-ingress-nginx-operator
```

#### Building the operator image

```bash
# make build
```

#### Installing the operator

```bash
# make install
```

#### Uninstalling the operator

```bash
# make uninstall
```

### Debugging guide

Use the following commands to debug the operator:

#### Check the Cluster Service Version (CSV) installation status

```bash
# oc get csv
# oc describe csv ibm-ingress-nginx-operator.v1.5.0
```

#### Check the operator status and log

```bash
# oc describe po -l name=ibm-ingress-nginx-operator
# oc logs -f $(oc get po -l name=ibm-ingress-nginx-operator -o name)
```

#### End-to-End testing using Operand Deployment Lifecycle Manager

See [ODLM guide](https://github.com/IBM/operand-deployment-lifecycle-manager/blob/9a5fdbfe33c93fcc95c3f9ad9022937a1b7fb003/docs/install/common-service-integration.md#end-to-end-test)
