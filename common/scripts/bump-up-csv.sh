#!/bin/bash
#
# Copyright 2021 IBM Corporation
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
# Create a new version of the operator and update the required files with the new version number.
#
# Run this script from the parent dir by typing "common/scripts/bump-up-csv.sh"
#
# Must use version 3 of yq: https://github.com/mikefarah/yq/releases/tag/3.4.1
# Also see https://mikefarah.gitbook.io/yq/v/v4.x/upgrading-from-v3

YQ=yq_v3
SED="sed"
unamestr=$(uname)
if [[ "$unamestr" == "Darwin" ]] ; then
    SED=gsed
    type $SED >/dev/null 2>&1 || {
        echo >&2 "$SED it's not installed. Try: brew install gnu-sed" ;
        exit 1;
    }
fi

# check the input parms
if [ -z "${1}" ]; then
    echo "Usage:   $0 [new CSV version]"
    exit 1
fi

if [ ! -f "$(command -v $YQ 2> /dev/null)" ]; then
    echo "[ERROR] $YQ command not found"
    exit 1
fi

OPERATOR_NAME=ibm-ingress-nginx-operator
NEW_CSV_VERSION=${1}
BASE_CSV_NAME=$OPERATOR_NAME.clusterserviceversion.yaml

CONFIG_DIR=config
BUNDLE_DIR=bundle
DEPLOY_DIR=${DEPLOY_DIR:-deploy/olm-catalog/${OPERATOR_NAME}}
# get the version number for the current/last CSV
LAST_CSV_DIR=$(find "${DEPLOY_DIR}" -maxdepth 1 -type d | sort | tail -1)
LAST_CSV_VERSION=$(basename "${LAST_CSV_DIR}")
NEW_CSV_DIR=${LAST_CSV_DIR//${LAST_CSV_VERSION}/${NEW_CSV_VERSION}}

PREVIOUS_CSV_DIR=$(find "${DEPLOY_DIR}" -maxdepth 1 -type d | sort | tail -2 | head -1)
PREVIOUS_CSV_VERSION=$(basename "${PREVIOUS_CSV_DIR}")

if [ "${LAST_CSV_VERSION}" == "${NEW_CSV_VERSION}" ]; then
    echo "Last CSV version is already at ${NEW_CSV_VERSION}"
    exit 1
fi

echo "******************************************"
echo " PREVIOUS_CSV_VERSION:  $PREVIOUS_CSV_VERSION"
echo " CURRENT_CSV_VERSION:   $LAST_CSV_VERSION"
echo " NEW_CSV_VERSION:       $NEW_CSV_VERSION"
echo "******************************************"
echo "Does the above look correct? (y/n) "
read -r ANSWER
if [[ "$ANSWER" != "y" ]]
then
  echo "Not going to bump up CSV version"
  exit 1
fi

echo -e "\n[INFO] Bumping up CSV version from ${LAST_CSV_VERSION} to ${NEW_CSV_VERSION}\n"

cp -rfv "${LAST_CSV_DIR}" "${NEW_CSV_DIR}"
OLD_CSV_FILE=$(find "${NEW_CSV_DIR}" -type f -name '*.clusterserviceversion.yaml' | head -1)
OLD_VERSION=$($YQ r "${OLD_CSV_FILE}" "metadata.name")

NEW_CSV_FILE=${OLD_CSV_FILE//${LAST_CSV_VERSION}.clusterserviceversion.yaml/${NEW_CSV_VERSION}.clusterserviceversion.yaml}
if [ -f "${OLD_CSV_FILE}" ]; then
    mv -v "${OLD_CSV_FILE}" "${NEW_CSV_FILE}"
fi

echo -e "\n[INFO] Updating ${NEW_CSV_FILE} from ${OLD_CSV_FILE}"

REPLACES_VERSION=$(${YQ} r "${NEW_CSV_FILE}" "metadata.name")
CURR_TIME=$(TZ=":UTC" date  +'%FT%R:00Z')

#---------------------------------------------------------
# update the CSV file
#---------------------------------------------------------
$SED -e "s|name: ${OPERATOR_NAME}\(.*\)${LAST_CSV_VERSION}|name: ${OPERATOR_NAME}\1${NEW_CSV_VERSION}|" -i "${NEW_CSV_FILE}"
$SED -e "s|olm.skipRange: \(.*\)${LAST_CSV_VERSION}\(.*\)|olm.skipRange: \1${NEW_CSV_VERSION}\2|" -i "${NEW_CSV_FILE}"
# use 'latest' for tag instead of CSV version
#$SED -e "s|image: \(.*\)${OPERATOR_NAME}\(.*\)|image: \1${OPERATOR_NAME}:${NEW_CSV_VERSION}|" -i "${NEW_CSV_FILE}"
$SED -e "s|containerImage: \(.*\)${OPERATOR_NAME}\(.*\)|containerImage: \1${OPERATOR_NAME}:${NEW_CSV_VERSION}|" -i "${NEW_CSV_FILE}"
$SED -e "s|replaces: ${OPERATOR_NAME}\(.*\)${PREVIOUS_CSV_VERSION}|replaces: ${REPLACES_VERSION}|" -i "${NEW_CSV_FILE}"
# update the operator version - version: n.n.n
$SED -e "s|version: ${LAST_CSV_VERSION}|version: ${NEW_CSV_VERSION}|" -i "${NEW_CSV_FILE}"
# update the 'createdAt' date. example:
#   createdAt: "2020-06-29T21:46:35Z"
#                           YYYY    -    MM    -    DD    T    HH    :   MM     :   SS     Z
#                       +----------+ +--------+ +--------+ +--------+ +--------+ +--------+
$SED -e "s|createdAt: \"\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}T[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}Z\)\"|createdAt: \"${CURR_TIME}\"|" -i "${NEW_CSV_FILE}"

#----------------------------------------------------------------------------------------------------------
# update package.yaml
#----------------------------------------------------------------------------------------------------------
PACKAGE_YAML=${DEPLOY_DIR}/${OPERATOR_NAME}.package.yaml
if ! [ -f "${PACKAGE_YAML}" ]; then
    echo "[WARN] ${PACKAGE_YAML} does not exist."
    exit 1
fi
NEW_VERSION=$($YQ r "${NEW_CSV_FILE}" "metadata.name")
echo -e "\n[INFO] Updating 'dev' channel in ${PACKAGE_YAML}"
$YQ w -i "${PACKAGE_YAML}" "channels.(name==dev).currentCSV" "${NEW_VERSION}" 
echo -e "\n[INFO] Updating 'beta' channel in ${PACKAGE_YAML}"
$YQ w -i "${PACKAGE_YAML}" "channels.(name==beta).currentCSV" "${NEW_VERSION}" 
echo -e "\n[INFO] Updating 'stable-v1' channel in ${PACKAGE_YAML}"
$YQ w -i "${PACKAGE_YAML}" "channels.(name==stable-v1).currentCSV" "${OLD_VERSION}" 

# remove the leading spaces added by "yq"
$SED -e "s|  - currentCSV:|- currentCSV:|g" -i "${PACKAGE_YAML}"
$SED -e "s|    name:|  name:|g" -i "${PACKAGE_YAML}"

#---------------------------------------------------------
# update version.go
#---------------------------------------------------------
VERSION_GO="version/version.go"
if ! [ -f "${VERSION_GO}" ]; then
    echo "[WARN] ${VERSION_GO} does not exist."
    exit 1
fi
echo -e "\n[INFO] Updating 'version' in ${VERSION_GO}"
$SED -e "s|Version\(.*\)${LAST_CSV_VERSION}\(.*\)|Version\1${NEW_CSV_VERSION}\2|" -i "${VERSION_GO}"

#---------------------------------------------------------
# update Chart.yaml
#---------------------------------------------------------
CHART_YAML=helm-charts/nginx-ingress/Chart.yaml
if ! [ -f "${CHART_YAML}" ]; then
    echo "[WARN] ${CHART_YAML} does not exist."
    exit 1
fi
echo -e "\n[INFO] Updating 'version' in ${CHART_YAML}"
$SED -e "s|version: ${LAST_CSV_VERSION}|version: ${NEW_CSV_VERSION}|" -i "${CHART_YAML}"

#---------------------------------------------------------
# update Makefile
#---------------------------------------------------------
MAKEFILE=Makefile
if ! [ -f "${MAKEFILE}" ]; then
    echo "[WARN] ${MAKEFILE} does not exist."
    exit 1
fi
echo -e "\n[INFO] Updating 'CSV_VERSION' in ${MAKEFILE}"
$SED -e "s|CSV_VERSION ?= ${LAST_CSV_VERSION}|CSV_VERSION ?= ${NEW_CSV_VERSION}|" -i "${MAKEFILE}"

#---------------------------------------------------------
# update multiarch_image.sh
#---------------------------------------------------------
MULTIARCH_SH=common/scripts/multiarch_image.sh
if ! [ -f "${MULTIARCH_SH}" ]; then
    echo "[WARN] ${MULTIARCH_SH} does not exist."
    exit 1
fi
echo -e "\n[INFO] Updating 'RELEASE_VERSION' in ${MULTIARCH_SH}"
$SED -e "s|RELEASE_VERSION\(.*\)${LAST_CSV_VERSION}\(.*\)|RELEASE_VERSION\1${NEW_CSV_VERSION}\2|" -i "${MULTIARCH_SH}"

#---------------------------------------------------------
# update README.md
#---------------------------------------------------------
README=README.md
if ! [ -f "${README}" ]; then
    echo "[WARN] ${README} does not exist."
    exit 1
fi
echo -e "\n[INFO] Adding version to ${README}"
$SED -i "/- ${LAST_CSV_VERSION}/a - ${NEW_CSV_VERSION}" "$README"
