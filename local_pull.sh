#!/bin/bash

BLUE=`tput setaf 4`
RESET=`tput sgr0`
USER=$1

echoOut() {
  echo "${BLUE}$1${RESET}"
}

if [[ -z $USER ]]; then
  echoOut "You need to supply the sfdx org alias which you are trying to deploy to"
  exit 1
fi

echoOut 'Copy .forceignore and add static resource to it'
cp .forceignore .forceignore.orig
echo -e "\nforce-app/main/default/staticresources" >> .forceignore

echoOut 'Pulling remote metadata...'

sfdx force:source:pull -u $USER -f

rm -f .forceignore
mv .forceignore.orig .forceignore