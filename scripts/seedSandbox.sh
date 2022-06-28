#!/bin/bash

RED=`tput setaf 1`
GREEN=`tput setaf 2`
BLUE=`tput setaf 4`
RESET=`tput sgr0`

SOURCE=$2
DESTINATION=$1

parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

echoRed() {
  echo "${RED}$1${RESET}"
}
echoGreen() {
  echo "${GREEN}$1${RESET}"
}
echoBlue() {
  echo "${BLUE}$1${RESET}"
}

if [[ -z $DESTINATION ]]; then
  echoRed "You need to supply the sfdx org alias which you are trying to Seed data into"
  exit 1
fi

if [[ -z $SOURCE ]]; then
  SOURCE='Production'
fi

verifySFDX(){
    if ! command -v sfdx &> /dev/null
    then
        echoRed "sfdx is not installed and is required. Check 'https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_install_cli.htm' for instructions"
        exit
    else
        echoGreen "Found sfdx"
    fi
}


verifySFDX
echo "$parent_path";
sfdx sfdmu:run --sourceusername "$SOURCE" --targetusername "$DESTINATION" --path "$parent_path"/../dataImport/SandboxSeed --verbose