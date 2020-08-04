#!/bin/bash
set -e

#accessToken="$(cat $BITBUCKET_CLONE_DIR/org_info.json | jq -r  '.accessToken')"
DEPLOY_EXPERIENCES=false
USER="$(cat $BITBUCKET_CLONE_DIR/org_info.json | jq -r '.username')"
echo "$USER"
sfdx sfpowerkit:auth:login -u $USER --password $1 -a ci-testValid

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

echo 'make a copy of .forceignore'
cp .forceignore .forceignore.orig

echo 'modifying .forceignore to not deploy staticresources and experienceBundles'
echo -e "\nforce-app/main/default/staticresources" >> .forceignore
echo -e "\nforce-app/main/default/experiences" >> .forceignore

sfdx force:source:deploy --testlevel RunLocalTests --checkonly --targetusername ci-testValid -p force-app/main/default -g -w 120

if [ $DEPLOY_EXPERIENCES = true ]
then
  echoOut 're-enable original .forceignore'
  rm -f .forceignore
  mv .forceignore.orig .forceignore
  echoOut 'Deploying ExperienceBundles'
  sfdx force:source:deploy --testlevel NoTestRun --checkonly --targetusername ci-testValid -p force-app/main/default/experiences -g -w 120
fi