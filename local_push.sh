#!/bin/bash

BLUE=`tput setaf 4`
RESET=`tput sgr0`
USER=$1
RAND="$(date +%s)"
CLONEDIR=".deploy_root_$RAND"

echoOut() {
  echo "${BLUE}$1${RESET}"
}

if [[ -z $USER ]]; then
  echo "You need to supply the sfdx org alias which you are trying to deploy to"
  exit 1
fi

cmd=$(pwd)
mkdir ~/$CLONEDIR
cd ~/$CLONEDIR
git clone $cmd .

chmod +x clean_code.sh
./clean_code.sh

echoOut 'Deploying static resources'
sfdx heber:staticresources:deploy -u $USER

echo 'make a copy of .forceignore'
cp .forceignore .forceignore.orig
echoOut 'modifying .forceignore to not deploy staticresources or experiences'
echo -e "\nforce-app/main/default/staticresources" >> .forceignore
echo -e "\nforce-app/main/default/experiences" >> .forceignore
echo 'Deploying the remaining metadata'

sfdx force:source:push -u $USER -f

echoOut 'Ceaning up'
cd .. && rm -fR $CLONEDIR
