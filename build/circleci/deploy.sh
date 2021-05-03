#!/bin/bash

echo "Deploying Static Resources"
sfdx heber:staticresources:deploy -u ci-deploy

cp .forceignore .forceignore.orig
echo -e "\nsrc/Base/main/default/staticresources" >> .forceignore
echo -e "\nsrc/BoatReservation/experiences" >> .forceignore
echo -e "\nsrc/CustomerCommunity/experiences" >> .forceignore
#echo -e "\nforce-app/FactoryStoreSites/experiences" >> .forceignore

if sfdx force:source:deploy --testlevel RunLocalTests --targetusername ci-deploy -p src/ -g -w 240 ; then
  rm -f .forceignore
  mv .forceignore.orig .forceignore
else
  echo "Deploy Failed"
  exit 1
fi