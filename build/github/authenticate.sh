#!/bin/bash

SERVERKEY=$1
USERNAME=$2
CLIENTID=$3
URL=$4

echo "Setting up Connection"
echo $SERVERKEY | base64 --decode > deploy.key

echo "Authenticating........"
sfdx force:auth:jwt:grant -u $USERNAME -i $CLIENTID -f deploy.key --setalias ci-deploy --instanceurl $URL