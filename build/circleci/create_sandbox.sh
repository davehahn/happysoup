#!/bin/bash

RAND="$(echo $CIRCLE_SHA1 | head -c6)"
SANDBOXNAME="sbtd${RAND}"
echo "$RAND"
echo "$SANDBOXNAME"

DEPLOY_KEY=$SFDC_SERVER_KEY
USERNAME=$PRODUCTION_USER
CONSUMER_KEY=$PRODUCTION_CONSUMER_KEY

mkdir -p workspace
echo $DEPLOY_KEY | base64 --decode > deploy.key
sfdx force:auth:jwt:grant -u $USERNAME -i $CONSUMER_KEY -f deploy.key --setalias ci-prod --instanceurl https://login.salesforce.com
sfdx force:org:create --type sandbox sandboxName=$SANDBOXNAME licenseType=Developer --targetusername ci-prod -a ValidateDeploy -w 120
sfdx force:org:display --targetusername ValidateDeploy --json  | jq  '.result' > workspace/org_info.json