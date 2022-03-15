#!/bin/bash

BLUE=`tput setaf 4`
RESET=`tput sgr0`
TESTLEVEL='RunLocalTest'
SFDX_ALIAS=$1
RAND="$(date +%s)"
CLONEDIR=".deploy_root_$RAND"

echoOut() {
  echo "${BLUE}$1${RESET}"
}

if [[ -z $SFDX_ALIAS ]]; then
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
mkdir ~/$CLONEDIR
cd ~/$CLONEDIR
git clone "${cmd}" .

echo "Set sfdx-project.json for FSL"
rm -f sfdx-project.json
mv sfdx-project.json.fsl sfdx-project.json

echo "Setting up .forceignore for FSL"
rm -f .forceignore
cp .forceignore.fsl .forceignore

chmod +x scripts/deploy.sh
./scripts/deploy.sh $SFDX_ALIAS $TESTLEVEL
echoOut 'Ceaning up'
cd .. && rm -fR $CLONEDIR