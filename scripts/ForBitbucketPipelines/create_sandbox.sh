#!/bin/bash

RAND="$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 6 | head -n 1)"
SANDBOXNAME="sbtd${RAND}"

echo "$SANDBOXNAME"
echo "$1"
echo "$2"
echo "$3"
echo "$4"

echo $1 | base64 --decode > deploy.key
sfdx force:auth:jwt:grant -u $2 -i $3 -f deploy.key --setalias ci-prod --instanceurl $4
sfdx force:org:create --type sandbox sandboxName=$SANDBOXNAME licenseType=Developer --targetusername ci-prod -a ValidateDeploy -w 120
sfdx force:org:display --targetusername ValidateDeploy --json  | jq  '.result' > org_info.json