#!/bin/bash
RED=`tput setaf 1`
RESET=`tput sgr0`

echoOut() {
  echo "${RED}$1${RESET}"
}

#Clean Metadata
echoOut 'Removing stupid Case Language field'
rm -f src/Base/main/default/objects/Case/fields/Language.field-meta.xml
echoOut 'Removing Lead list views'
rm -fR src/Base/main/default/objects/Lead/listViews
echoOut 'Removing Opportunity list views'
rm -fR src/Base/main/default/objects/Opportunity/listViews
echoOut 'Removing Lead IqScore field'
rm -f src/Base/main/default/objects/Lead/fields/IqScore.field-meta.xml
echoOut 'Removing Opportunity IqScore field'
rm -f src/Base/main/default/objects/Opportunity/fields/IqScore.field-meta.xml
echoOut 'Removing troublesome LiveChatTranscript layouts'
rm -f src/Base/main/default/layouts/LiveChatTranscriptActive-Live\ Chat\ Transcript\ %28In\ Progress%29\ Layout.layout-meta.xml
rm -f src/Base/main/default/layouts/LiveChatTranscriptWaiting-Live\ Chat\ Transcript\ %28Waiting%29\ Layout.layout-meta.xml
echoOut 'Removing Accounting Home1 tab'
rm -f src/Base/main/default/tabs/AcctSeed__Accounting_Home1.tab-meta.xml
echoOut 'removing mcdm_15__ weblinks from Account'
rm -f src/Base/main/default/objects/Account/webLinks/mcdm_15__*
echoOut 'removing mcdm_15__ weblinks from Lead'
rm -f src/Base/main/default/objects/Lead/webLinks/mcdm_15__*
echoOut 'removing mcdm_15__ weblinks from Contact'
rm -f src/Base/main/default/objects/Contact/webLinks/mcdm_15__*
echoOut 'Running ant doMetadataClean'
ant -buildfile build/build.xml doMetadataClean


