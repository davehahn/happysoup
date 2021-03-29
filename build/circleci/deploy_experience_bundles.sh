#!/bin/bash

echo "Deploying Experience Bundles"
sfdx force:source:deploy --testlevel NoTestRun --targetusername ci-deploy -p force-app/main/default/experiences -g -w 120
sfdx force:source:deploy --testlevel NoTestRun --targetusername ci-deploy -p force-app/BoatReservation/experiences -g -w 120