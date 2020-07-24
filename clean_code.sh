#!/bin/bash

#Clean Metadata
echo 'Removing stupid Case Language field'
rm -f force-app/main/default/objects/Case/fields/Language.field-meta.xml
echo 'Removing Lead list views'
rm -fR force-app/main/default/objects/Lead/listViews
echo 'Removing Opportunity list views'
rm -fR force-app/main/default/objects/Opportunity/listViews
echo 'Removing Lead IqScore field'
rm -f force-app/main/default/objects/Lead/fields/IqScore.field-meta.xml
echo 'Removing Opportunity IqScore field'
rm -f force-app/main/default/objects/Opportunity/fields/IqScore.field-meta.xml
echo 'Removing troublesome LiveChatTranscript layouts'
rm -f force-app/main/default/layouts/LiveChatTranscriptActive-Live\ Chat\ Transcript\ %28In\ Progress%29\ Layout.layout-meta.xml
rm -f force-app/main/default/layouts/LiveChatTranscriptWaiting-Live\ Chat\ Transcript\ %28Waiting%29\ Layout.layout-meta.xml
echo 'Removing Accounting Home1 tab'
rm -f force-app/main/default/tabs/AcctSeed__Accounting_Home1.tab-meta.xml
echo 'removing mcdm_15__ weblinks from Account'
rm -f force-app/main/default/objects/Account/webLinks/mcdm_15__*
echo 'removing mcdm_15__ weblinks from Lead'
rm -f force-app/main/default/objects/Lead/webLinks/mcdm_15__*
echo 'removing mcdm_15__ weblinks from Contact'
rm -f force-app/main/default/objects/Contact/webLinks/mcdm_15__*
echo 'Running ant doMetadataClean'
ant -buildfile build/build.xml doMetadataClean


