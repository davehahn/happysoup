#!/bin/bash
set -e

#accessToken="$(cat $BITBUCKET_CLONE_DIR/org_info.json | jq -r  '.accessToken')"
DEPLOY_EXPERIENCES=false
USER="$(cat $BITBUCKET_CLONE_DIR/org_info.json | jq -r '.username')"
echo "$USER"
sfdx sfpowerkit:auth:login -u $USER --password $1 -a ci-testValid

#Clean Metadata
echo 'Removing stupid Case Language field'
rm -f src/Base/main/default/objects/Case/fields/Language.field-meta.xml
echo 'Removing Lead list views'
rm -fR src/Base/main/default/objects/Lead/listViews
echo 'Removing Opportunity list views'
rm -fR src/Base/main/default/objects/Opportunity/listViews
echo 'Removing Lead IqScore field'
rm -f src/Base/main/default/objects/Lead/fields/IqScore.field-meta.xml
echo 'Removing Opportunity IqScore field'
rm -f src/Base/main/default/objects/Opportunity/fields/IqScore.field-meta.xml
echo 'Removing troublesome LiveChatTranscript layouts'
rm -f src/Base/main/default/layouts/LiveChatTranscriptActive-Live\ Chat\ Transcript\ %28In\ Progress%29\ Layout.layout-meta.xml
rm -f src/Base/main/default/layouts/LiveChatTranscriptWaiting-Live\ Chat\ Transcript\ %28Waiting%29\ Layout.layout-meta.xml
echo 'Removing Accounting Home1 tab'
rm -f src/Base/main/default/tabs/AcctSeed__Accounting_Home1.tab-meta.xml
echo 'removing mcdm_15__ weblinks from Account'
rm -f src/Base/main/default/objects/Account/webLinks/mcdm_15__*
echo 'removing mcdm_15__ weblinks from Lead'
rm -f src/Base/main/default/objects/Lead/webLinks/mcdm_15__*
echo 'removing mcdm_15__ weblinks from Contact'
rm -f src/Base/main/default/objects/Contact/webLinks/mcdm_15__*
echo 'Running ant doMetadataClean'
ant -buildfile build/build.xml doMetadataClean

echo 'make a copy of .forceignore'
cp .forceignore .forceignore.orig

echo 'modifying .forceignore to not deploy staticresources and experienceBundles'
echo -e "\nsrc/Base/main/default/staticresources" >> .forceignore
echo -e "\nsrc/BoatReservation/experiences" >> .forceignore
echo -e "\nsrc/CustomerCommunity/experiences" >> .forceignore
#echo -e "\nsrc/Base/FactoryStoreSites/experiences" >> .forceignore

sfdx force:source:deploy --testlevel RunLocalTests --checkonly --targetusername ci-testValid -p src/ -g -w 120

if [ $DEPLOY_EXPERIENCES = true ]
then
  echoOut 're-enable original .forceignore'
  rm -f .forceignore
  mv .forceignore.orig .forceignore
  echoOut 'Deploying ExperienceBundles'
  sfdx force:source:deploy --testlevel NoTestRun --checkonly --targetusername $1 -p src/BoatReservation/experiences -g -w 180
  sfdx force:source:deploy --testlevel NoTestRun --checkonly --targetusername $1 -p src/CustomerCommunity/experiences -g -w 180
  sfdx force:source:deploy --testlevel NoTestRun --checkonly --targetusername $1 -p src/FactoryStoreSites/experiences -g -w 180
fi