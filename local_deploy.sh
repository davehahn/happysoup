#!/bin/bash

BLUE=`tput setaf 4`
RESET=`tput sgr0`
TESTLEVEL='RunLocalTest'

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

if [ -z $3 ]
then
  echoOut 'Deployment running'
else
  CHECKONLY=true
  echoOut "Validating Only"
fi

cmd=$(pwd)
mkdir ~/.deploy_root
cd ~/.deploy_root
git clone $cmd .
chmod +x deploy.sh
./deploy.sh $1 $TESTLEVEL
echoOut 'Ceaning up'
cd .. && rm -fR .deploy_root