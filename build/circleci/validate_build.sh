#!/bin/bash
set -e

#accessToken="$(cat $BITBUCKET_CLONE_DIR/org_info.json | jq -r  '.accessToken')"
DEPLOY_EXPERIENCES=false
USER="$(cat /workspace/org_info.json | jq -r '.username')"
echo "$USER"
sfdx sfpowerkit:auth:login -u $USER --password $PRODUCTION_PASSWORD -a ci-testValid

echo 'make a copy of .forceignore'
cp .forceignore .forceignore.orig

echo 'modifying .forceignore to not deploy staticresources and experienceBundles'
echo -e "\nforce-app/main/default/staticresources" >> .forceignore
echo -e "\nforce-app/BoatReservation/experiences" >> .forceignore
echo -e "\nforce-app/CustomerCommunity/experiences" >> .forceignore
#echo -e "\nforce-app/FactoryStoreSite/experiences" >> .forceignore

sfdx force:source:deploy --testlevel RunLocalTests --checkonly --targetusername ci-testValid -p force-app -g -w 240

if [ $DEPLOY_EXPERIENCES = true ]
then
  echoOut 're-enable original .forceignore'
  rm -f .forceignore
  mv .forceignore.orig .forceignore
  echoOut 'Deploying ExperienceBundles'
  sfdx force:source:deploy --testlevel NoTestRun --checkonly --targetusername ci-testValid -p force-app/BoatReservation/experiences -g -w 240
  sfdx force:source:deploy --testlevel NoTestRun --checkonly --targetusername ci-testValid -p force-app/CustomerCommunity/experiences -g -w 240
  #sfdx force:source:deploy --testlevel NoTestRun --checkonly --targetusername ci-testValid -p force-app/FactoryStoreSite/experiences -g -w 240
fi