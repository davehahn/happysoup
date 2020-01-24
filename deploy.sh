#!/bin/bash

BLUE=`tput setaf 4`
RESET=`tput sgr0`
TESTLEVEL='RunLocalTest'
CHECKONLY=false

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
echoOut 'Running ant doMetadataClean'
ant -buildfile build/build.xml doMetadataClean
echoOut 'Deploying static resources'
sfdx heber:staticresources:deploy -u $1
echo 'Deploying the remaining metadata'

if [ "$CHECKONLY" = true ]
then
  echoOut 'VALIDATING ONLY'
  sfdx force:source:deploy --testlevel $TESTLEVEL --checkonly --targetusername $1 -p force-app/main/default -g -w 120
else
  sfdx force:source:deploy --testlevel $TESTLEVEL --targetusername $1 -p force-app/main/default -g -w 120
fi
