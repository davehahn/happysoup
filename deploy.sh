#!/bin/bash

echo $1 | base64 --decode > deploy.key
sfdx force:auth:jwt:grant -i $3 -u $2 -f deploy.key --setalias ci-deploy --instanceurl $4
./local_deploy.sh ci-deploy RunLocalTests
