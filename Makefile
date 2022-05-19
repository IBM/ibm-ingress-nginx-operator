# Copyright 2020,2021 IBM Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#


# Default goal
.DEFAULT_GOAL:=help
GIT_COMMIT_ID=$(shell git rev-parse --short HEAD)

# Specify whether this repo is build locally or not, default values is '1';
# If set to 1, then you need to also set 'DOCKER_USERNAME' and 'DOCKER_PASSWORD'
# environment variables before build the repo.
BUILD_LOCALLY ?= 1

# The namespace that the test operator will be deployed in
NAMESPACE ?= ibm-common-services

# Image URL to use all building/pushing image targets;
# Use your own docker registry and image name for dev/test by overridding the
# IMAGE_REPO, IMAGE_NAME and RELEASE_TAG environment variable.
IMAGE_REPO ?= hyc-cloud-private-integration-docker-local.artifactory.swg-devops.com/ibmcom
IMAGE_NAME ?= ibm-ingress-nginx-operator
CSV_VERSION ?= 1.16.0
IMAGE_BUILD_OPTS=--build-arg "VCS_REF=$(GIT_COMMIT_ID)" --build-arg "VCS_URL=$(GIT_REMOTE_URL)"

# Github host to use for checking the source tree;
# Override this variable ue with your own value if you're working on forked repo.
GIT_HOST ?= github.com

VERSION ?= $(shell date +v%Y%m%d)-$(shell git describe --match=$(git rev-parse --short=8 HEAD) --tags --always --dirty)
RELEASE_VERSION ?= $(shell cat ./version/version.go | grep "Version =" | awk '{ print $$3}' | tr -d '"')

LOCAL_OS := $(shell uname)
ifeq ($(LOCAL_OS),Linux)
    TARGET_OS ?= linux
    XARGS_FLAGS="-r"
else ifeq ($(LOCAL_OS),Darwin)
    TARGET_OS ?= darwin
    XARGS_FLAGS=
else
    $(error "This system's OS $(LOCAL_OS) isn't recognized/supported")
endif

ARCH := $(shell uname -m)
LOCAL_ARCH := "amd64"
ifeq ($(ARCH),x86_64)
    LOCAL_ARCH="amd64"
else ifeq ($(ARCH),ppc64le)
    LOCAL_ARCH="ppc64le"
else ifeq ($(ARCH),s390x)
    LOCAL_ARCH="s390x"
else
    $(error "This system's ARCH $(ARCH) isn't recognized/supported")
endif

all: fmt check test coverage build-image images

include common/Makefile.common.mk

############################################################
# format section
############################################################

# All available format: format-go format-python
# Default value will run all formats, override these make target with your requirements:
#    eg: fmt: format-go format-protos
fmt: format-go format-python

############################################################
# check section
############################################################

check: lint

# All available linters: lint-dockerfiles lint-scripts lint-yaml lint-copyright-banner lint-go lint-python lint-helm lint-markdown
# Default value will run all linters, override these make target with your requirements:
#    eg: lint: lint-go lint-yaml
# The MARKDOWN_LINT_WHITELIST variable can be set with comma separated urls you want to whitelist
lint: lint-all

############################################################
# test section
############################################################

test: test-e2e ## Run integration e2e tests with different options

test-e2e:
	@echo ... Running the same e2e tests with different args ...
	@echo ... Running locally ...
	- operator-sdk test local ./test/e2e --verbose --up-local --namespace=${NAMESPACE}
	# @echo ... Running with the param ...
	# - operator-sdk test local ./test/e2e --namespace=${NAMESPACE}

scorecard: ## Run scorecard test
	@echo ... Running the scorecard test
	- operator-sdk scorecard --verbose

############################################################
# coverage section
############################################################

coverage:
	@common/scripts/codecov.sh

############################################################
# build image section
############################################################
ifeq ($(BUILD_LOCALLY),0)
    export CONFIG_DOCKER_TARGET = config-docker
endif

build: build-image

build-image: $(CONFIG_DOCKER_TARGET)
	echo "CONFIG_DOCKER_TARGET=$CONFIG_DOCKER_TARGET"
	@echo "Building the $(IMAGE_NAME) image for $(LOCAL_ARCH)..."
	@docker build -f build/Dockerfile-$(LOCAL_ARCH) ${IMAGE_BUILD_OPTS} -t $(IMAGE_REPO)/$(IMAGE_NAME)-$(LOCAL_ARCH):$(VERSION) .

############################################################
# push image section
############################################################

push-image: $(CONFIG_DOCKER_TARGET) build-image
	@echo "Pushing the $(IMAGE_NAME) image for $(LOCAL_ARCH)..."
	@docker push $(IMAGE_REPO)/$(IMAGE_NAME)-$(LOCAL_ARCH):$(VERSION)

############################################################
# multiarch-image section
############################################################

images: $(CONFIG_DOCKER_TARGET) build-image push-image multiarch-image

multiarch-image: $(CONFIG_DOCKER_TARGET)
	@echo "Build multiarch image for $(IMAGE_REPO)/$(IMAGE_NAME):$(RELEASE_VERSION)..."
	@common/scripts/multiarch_image.sh $(IMAGE_REPO) $(IMAGE_NAME) $(VERSION) $(RELEASE_VERSION)

############################################################
# push CSV section
############################################################

csv:
	@RELEASE=${CSV_VERSION} common/scripts/push-csv.sh

############################################################
# clean section
############################################################
clean:
	@rm -rf build/_output

############################################################
# help section
############################################################
help: ## Display this help
	@echo "Usage:\n  make \033[36m<target>\033[0m"
	@awk 'BEGIN {FS = ":.*##"}; \
		/^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } \
		/^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: all fmt check coverage test build-image multiarch-image images clean
