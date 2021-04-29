#!/bin/bash

echo "Deploying Static Resources"
sfdx heber:staticresources:deploy -u ci-deploy

cp .forceignore .forceignore.orig
echo -e "\nforce-app/main/default/staticresources" >> .forceignore
echo -e "\nforce-app/BoatReservation/experiences" >> .forceignore
echo -e "\nforce-app/CustomerCommunity/experiences" >> .forceignore
#echo -e "\nforce-app/FactoryStoreSites/experiences" >> .forceignore

if sfdx force:source:deploy --testlevel RunLocalTests --targetusername ci-deploy -p force-app/ -g -w 240 ; then
  rm -f .forceignore
  mv .forceignore.orig .forceignore
else
  echo "Deploy Failed"
  exit 1
fi