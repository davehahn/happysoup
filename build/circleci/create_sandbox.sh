#!/bin/bash

RAND="$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 6 | head -n 1)"
SANDBOXNAME="sbtd${RAND}"

DEPLOY_KEY=$SFDC_SERVER_KEY
USERNAME=$PRODUCTION_USER
CONSUMER_KEY=$PRODUCTION_CONSUMER_KEY

echo $DEPLOY_KEY | base64 --decode > deploy.key
sfdx force:auth:jwt:grant -u $USERNAME -i $CONSUMER_KEY -f deploy.key --setalias ci-prod --instanceurl https://login.salesforce.com
sfdx force:org:create --type sandbox sandboxName=$SANDBOXNAME licenseType=Developer --targetusername ci-prod -a ValidateDeploy -w 120
sfdx force:org:display --targetusername ValidateDeploy --json  | jq  '.result' > /tmp/org_info.json