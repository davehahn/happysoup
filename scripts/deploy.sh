
#!/bin/bash

BLUE=`tput setaf 4`
RESET=`tput sgr0`
TESTLEVEL='RunLocalTest'
CHECKONLY=false
DEPLOY_EXPERIENCES=false

echoOut() {
  echo "${BLUE}$1${RESET}"
}

if [[ -z $1 ]]; then
  echo "You need to supply the sfdx org alias which you are trying to deploy to"
  exit 1
fi

if [ -z $2 ]
then
  TESTLEVEL='NoTestRun'
  echoOut 'Deployment running with NO TESTS - Sandbox ONLY'
else
  TESTLEVEL=$2
  echoOut "Deployment running with --testlevel=$2"
fi

if [ ! -z $3 ] && [ $3 = true ]
then
  CHECKONLY=true
fi

if [ ! -z $4 ] && [ $4 = true ]
then
  DEPLOY_EXPERIENCES=true
fi

echoOut "Cleaning up undeployable/unwanted code...."
chmod +x scripts/clean_code.sh
./scripts/clean_code.sh

echoOut 'Deploying static resources'
sfdx heber:staticresources:deploy -u $1

echoOut 'make a copy of .forceignore'
cp .forceignore .forceignore.orig

echoOut 'modifying .forceignore to not deploy staticresources or experiences'
echo -e "\nsrc/Base/main/default/staticresources" >> .forceignore
echo -e "\nsrc/BoatReservation/experiences" >> .forceignore
echo -e "\nsrc/CustomerCommunity/experiences" >> .forceignore
echo -e "\nsrc/FactoryStoreSites/experiences" >> .forceignore

echoOut 'Deploying the remaining metadata'

if [ "$CHECKONLY" = true ]
then
  echoOut 'VALIDATING ONLY'
  if sfdx force:source:deploy --testlevel $TESTLEVEL --checkonly --targetusername $1 -p src/ -g -w 180 ; then
    if [ $DEPLOY_EXPERIENCES = true ]
    then
      echoOut 're-enable original .forceignore'
      rm -f .forceignore
      mv .forceignore.orig .forceignore
      echoOut 'Deploying ExperienceBundles'
      sfdx force:source:deploy --testlevel NoTestRun --checkonly --targetusername $1 -p src/BoatReservation/experiences -g -w 180
      sfdx force:source:deploy --testlevel NoTestRun --checkonly --targetusername $1 -p src/CustomerCommunity/experiences -g -w 180
      sfdx force:source:deploy --testlevel NoTestRun --checkonly --targetusername $1 -p src/FactoryStoreSites/experiences -g -w 180
    fi
  else
    echoOut 'Validation Fail'
    exit 1
  fi
else
  if sfdx force:source:deploy --testlevel $TESTLEVEL --targetusername $1 -p src -g -w 180 ; then
    if [ $DEPLOY_EXPERIENCES = true ]
    then
      echoOut 're-enable original .forceignore'
      rm -f .forceignore
      mv .forceignore.orig .forceignore
      echoOut 'Deploying ExperienceBundles'
      sfdx force:source:deploy --testlevel NoTestRun --targetusername $1 -p src/BoatReservation/experiences -g -w 180
      sfdx force:source:deploy --testlevel NoTestRun --targetusername $1 -p src/CustomerCommunity/experiences -g -w 180
      sfdx force:source:deploy --testlevel NoTestRun --targetusername $1 -p src/FactoryStoreSites/experiences -g -w 180
    fi
  else
    echoOut 'Deploy Fail'
    exit 1
  fi
fi
