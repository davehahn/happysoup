#!/bin/bash
set -e

#accessToken="$(cat $BITBUCKET_CLONE_DIR/org_info.json | jq -r  '.accessToken')"
DEPLOY_EXPERIENCES=false
USER="$(cat /workspace/org_info.json | jq -r '.username')"
echo "$USER"
sfdx sfpowerkit:auth:login -u $USER --password $PRODUCTION_PASSWORD -a ci-testValid

echo "Set sfdx-project.json for production"
rm -f sfdx-project.json
mv sfdx-project.json.prod sfdx-project.json

echo "Deploying Static Resources"
sfdx heber:staticresources:deploy -u ci-testValid

echo "Setting up .forceignore for Prod"
rm -f .forceignore
cp .forceignore.prod .forceignore

echo 'make a copy of .forceignore'
cp .forceignore .forceignore.orig

echo 'modifying .forceignore to not deploy staticresources and experienceBundles'
echo -e "\nsrc/Base/main/default/staticresources" >> .forceignore
echo -e "\nsrc/BoatReservation/experiences" >> .forceignore
echo -e "\nsrc/CustomerCommunity/experiences" >> .forceignore
#echo -e "\nsrc/FactoryStoreSite/experiences" >> .forceignore

sfdx force:source:deploy --verbose --testlevel RunLocalTests --targetusername ci-testValid -p src/ -g -w 240

if [ $DEPLOY_EXPERIENCES = true ]
then
  echoOut 're-enable original .forceignore'
  rm -f .forceignore
  cp .forceignore.prod .forceignore
  echoOut 'Deploying ExperienceBundles'
  sfdx force:source:deploy --testlevel NoTestRun --targetusername ci-testValid -p src/BoatReservation/experiences -g -w 240
  sfdx force:source:deploy --testlevel NoTestRun --targetusername ci-testValid -p src/CustomerCommunity/experiences -g -w 240
  sfdx force:source:deploy --testlevel NoTestRun --targetusername ci-testValid -p src/FactoryStoreSite/experiences -g -w 240
fi
