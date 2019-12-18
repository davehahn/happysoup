#!/bin/bash

if [[ -z $1 ]]; then
  echo "You need to supply a sfdx org alias"
  exit 1
fi
cmd=$(pwd)
mkdir ~/.deploy_root
cd ~/.deploy_root
git clone $cmd .
rm -fR force-app/main/default/objects/Lead/listViews
rm -fR force-app/main/default/objects/Opportunity/listViews
rm -f force-app/main/default/objects/Lead/fields/IqScore.field-meta.xml
rm -f force-app/main/default/objects/Opportunity/fields/IqScore.field-meta.xml
rm -f force-app/main/default/layouts/LiveChatTranscriptActive-Live\ Chat\ Transcript\ %28In\ Progress%29\ Layout.layout-meta.xml
rm -f force-app/main/default/layouts/LiveChatTranscriptWaiting-Live\ Chat\ Transcript\ %28Waiting%29\ Layout.layout-meta.xml
ant -buildfile build/build.xml doMetadataClean
#sfdx heber:staticresources:deploy -u $1
#sfdx force:source:deploy --testlevel RunLocalTests --targetusername $1 -p force-app/main/default -w 120
#sfdx force:source:deploy --targetusername $1 -p force-app/main/default --verbose
#cd .. && rm -fR .deploy_root