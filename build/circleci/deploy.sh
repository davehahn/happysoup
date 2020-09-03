#!/bin/bash

echo "Deploying Static Resources"
sfdx heber:staticresources:deploy -u ci-deploy

cp .forceignore .forceignore.orig
echo -e "\nforce-app/main/default/staticresources" >> .forceignore
echo -e "\nforce-app/main/default/experiences" >> .forceignore

if sfdx force:source:deploy --testlevel RunLocalTests --targetusername ci-deploy -p force-app/main/default -g -w 120 ; then
  rm -f .forceignore
  mv .forceignore.orig .forceignore
else
  echo "Deploy Failed"
  exit 1
fi