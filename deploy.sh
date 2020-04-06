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

if [ -z "`git log master..`" ]
then
  echoOut "Must be a new Branch - Exiting"
  exit 0
fi

echoOut 'Removing Lead list views'
rm -fR force-app/main/default/objects/Lead/listViews
echoOut 'Removing Opportunity list views'
rm -fR force-app/main/default/objects/Opportunity/listViews
echoOut 'Removing Lead IqScore field'
rm -f force-app/main/default/objects/Lead/fields/IqScore.field-meta.xml
echoOut 'Removing Opportunity IqScore field'
rm -f force-app/main/default/objects/Opportunity/fields/IqScore.field-meta.xml
echoOut 'Removing troublesome LiveChatTranscript layouts'
rm -f force-app/main/default/layouts/LiveChatTranscriptActive-Live\ Chat\ Transcript\ %28In\ Progress%29\ Layout.layout-meta.xml
rm -f force-app/main/default/layouts/LiveChatTranscriptWaiting-Live\ Chat\ Transcript\ %28Waiting%29\ Layout.layout-meta.xml
echoOut 'Removing Accounting Home1 tab'
rm -f force-app/main/default/tabs/AcctSeed__Accounting_Home1.tab-meta.xml
echoOut 'removing mcdm_15__ weblinks from Account'
rm -f force-app/main/default/objects/Account/webLinks/mcdm_15__*
echoOut 'removing mcdm_15__ weblinks from Lead'
rm -f force-app/main/default/objects/Lead/webLinks/mcdm_15__*
echoOut 'removing mcdm_15__ weblinks from Contact'
rm -f force-app/main/default/objects/Contact/webLinks/mcdm_15__*
echoOut 'Running ant doMetadataClean'
ant -buildfile build/build.xml doMetadataClean
echoOut 'Deploying static resources'
sfdx heber:staticresources:deploy -u $1
echoOut 'modifying .forceignore to not deploy staticresources'
echo -e "\nforce-app/main/default/staticresources" >> .forceignore
echo 'Deploying the remaining metadata'
sfdx force:source:deploy --testlevel $TESTLEVEL --targetusername $1 -p force-app/main/default -g -w 120
