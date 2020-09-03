#!/bin/bash

USERNAME=$1
CLIENTID=$2
URL=$3

echo "Setting up Connection"
echo $SFDC_SERVER_KEY | base64 --decode > deploy.key

echo "Authenticating........"
sfdx force:auth:jwt:grant -u $USERNAME -i $CLIENTID -f deploy.key --setalias ci-deploy --instanceurl $URL
