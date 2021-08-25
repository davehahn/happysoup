#!/bin/bash

set -e

SANDBOXNAME="sbtd${CIRCLE_BUILD_NUM}"
DEPLOY_KEY=$SFDC_SERVER_KEY
USERNAME=$PRODUCTION_USER
CONSUMER_KEY=$PRODUCTION_CONSUMER_KEY
SANDBOXUSER="${USERNAME}.${SANDBOXNAME}"

echo "$SANDBOXNAME"
echo "$SANDBOXUSER"
echo ""

echo "SFDX Version"
sfdx --version
echo ""
echo "jq version"
jq --version

mkdir -p workspace
echo $DEPLOY_KEY | base64 --decode > deploy.key
echo "Authorizing CLI for Production"
echo ""
sfdx force:auth:jwt:grant -u $USERNAME -i $CONSUMER_KEY -f deploy.key --setalias ci-prod --instanceurl https://login.salesforce.com

echo "Creating Sandbox"
echo ""
sfdx force:org:create --type sandbox sandboxName=$SANDBOXNAME licenseType=Developer --targetusername ci-prod -a ValidateDeploy -w 120
echo "Saving Sandbox info to workspace"
#sfdx force:org:display --targetusername ValidateDeploy --json | jq  '.result' > workspace/org_info.json
#jq . < workspace/org_info.json

sfdx force:org:display --targetusername $SANDBOXUSER --json | jq  '.result' > workspace/org_info.json
echo "Org Info"
jq . < workspace/org_info.json