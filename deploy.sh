#!/bin/bash

BLUE=`tput setaf 4`
RESET=`tput sgr0`

echoOut() {
  echo "${BLUE}$1${RESET}"
}

if [[ -z $1 ]]; then
  echo "You need to supply the sfdx org alias which you are trying to deploy to"
  exit 1
fi

cmd=$(pwd)
mkdir ~/.deploy_root
cd ~/.deploy_root
git clone $cmd .
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
echoOut 'Running ant doMetadataClean'
ant -buildfile build/build.xml doMetadataClean
git commit -am 'post metadata clean'
echoOut 'Deploying static resources'
sfdx heber:staticresources:deploy -u $1
echo 'Deploying the remaining metadata'
#sfdx force:source:deploy --testlevel RunLocalTests --targetusername $1 -p force-app/main/default -w 120
sfdx force:source:deploy --targetusername $1 -p force-app/main/default --verbose
echoOut 'Ceaning up'
cd .. && rm -fR .deploy_root