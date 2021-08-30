#!/bin/bash

echo "Deploying Experience Bundles"
sfdx force:source:deploy --testlevel NoTestRun --targetusername ci-deploy -p src/BoatReservation/experiences -g -w 120
sfdx force:source:deploy --testlevel NoTestRun --targetusername ci-deploy -p src/CustomerCommunity/experiences -g -w 120
sfdx force:source:deploy --testlevel NoTestRun --targetusername ci-deploy -p src/FactoryStoreSites/experiences -g -w 120