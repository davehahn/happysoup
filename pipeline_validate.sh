#!/bin/bash
if [ -z "`git log master..`" ]
then
  echoOut "Must be a new Branch - Exiting"
  exit 0
fi

echo $1 | base64 --decode > deploy.key
sfdx force:auth:jwt:grant -u $2 -i $3 -f deploy.key --setalias ci-deploy --instanceurl $4
chmod +x deploy.sh
./deploy.sh ci-deploy RunLocalTests true