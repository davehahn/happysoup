#!/bin/bash

SOURCE_DIR=${1}

if [[ -z $SOURCE_DIR ]]; then
  SOURCE_DIR='src'
fi

echo 'Removing stupid Case Language field'
rm -f ${SOURCE_DIR}/Base/main/default/objects/Case/fields/Language.field-meta.xml
echo 'Removing Lead list views'
rm -fR ${SOURCE_DIR}/Base/main/default/objects/Lead/listViews
echo 'Removing Opportunity list views'
rm -fR ${SOURCE_DIR}/Base/main/default/objects/Opportunity/listViews
echo 'Removing Lead IqScore field'
rm -f ${SOURCE_DIR}/Base/main/default/objects/Lead/fields/IqScore.field-meta.xml
echo 'Removing Opportunity IqScore field'
rm -f ${SOURCE_DIR}/Base/main/default/objects/Opportunity/fields/IqScore.field-meta.xml
echo 'Removing troublesome LiveChatTranscript layouts'
rm -f ${SOURCE_DIR}/Base/main/default/layouts/LiveChatTranscriptActive-Live\ Chat\ Transcript\ %28In\ Progress%29\ Layout.layout-meta.xml
rm -f ${SOURCE_DIR}/Base/main/default/layouts/LiveChatTranscriptWaiting-Live\ Chat\ Transcript\ %28Waiting%29\ Layout.layout-meta.xml
echo 'Removing Accounting Home1 tab'
rm -f ${SOURCE_DIR}/Base/main/default/tabs/AcctSeed__Accounting_Home1.tab-meta.xml
echo 'removing mcdm_15__ weblinks from Account'
rm -f ${SOURCE_DIR}/Base/main/default/objects/Account/webLinks/mcdm_15__*
echo 'removing mcdm_15__ weblinks from Lead'
rm -f ${SOURCE_DIR}/Base/main/default/objects/Lead/webLinks/mcdm_15__*
echo 'removing mcdm_15__ weblinks from Contact'
rm -f ${SOURCE_DIR}/Base/main/default/objects/Contact/webLinks/mcdm_15__*
echo 'Running ant cleanCode'
ant -buildfile build/clean_code.xml -DsourceDir=${SOURCE_DIR}