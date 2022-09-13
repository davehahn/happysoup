#!/bin/bash

echo "Deploying Static Resources"
sfdx heber:staticresources:deploy -u ci-deploy

echo "Setting up .forceignore for Prod"
rm -f .forceignore
cp .forceignore.prod .forceignore

echo -e "\nsrc/Base/main/default/staticresources" >> .forceignore
echo -e "\nsrc/BoatReservation/experiences" >> .forceignore
echo -e "\nsrc/CustomerCommunity/experiences" >> .forceignore
#echo -e "\nsrc/FactoryStoreSites/experiences" >> .forceignore

./build/github/deploy2.sh "src" "RunLocalTests"