
#!/bin/bash

BLUE=`tput setaf 4`
RESET=`tput sgr0`
TESTLEVEL='RunLocalTest'
CHECKONLY=false
DEPLOY_EXPERIENCES=false

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

if [ ! -z $4 ] && [ $4 = true ]
then
  DEPLOY_EXPERIENCES=true
fi

echoOut 'Removing stupid Case Language field'
rm -f src/main/default/objects/Case/fields/Language.field-meta.xml
echoOut 'Removing Lead list views'
rm -fR src/main/default/objects/Lead/listViews
echoOut 'Removing Opportunity list views'
rm -fR src/main/default/objects/Opportunity/listViews
echoOut 'Removing Lead IqScore field'
rm -f src/main/default/objects/Lead/fields/IqScore.field-meta.xml
echoOut 'Removing Opportunity IqScore field'
rm -f src/main/default/objects/Opportunity/fields/IqScore.field-meta.xml
echoOut 'Removing troublesome LiveChatTranscript layouts'
rm -f src/main/default/layouts/LiveChatTranscriptActive-Live\ Chat\ Transcript\ %28In\ Progress%29\ Layout.layout-meta.xml
rm -f src/main/default/layouts/LiveChatTranscriptWaiting-Live\ Chat\ Transcript\ %28Waiting%29\ Layout.layout-meta.xml
echoOut 'Removing Accounting Home1 tab'
rm -f src/main/default/tabs/AcctSeed__Accounting_Home1.tab-meta.xml
echoOut 'removing mcdm_15__ weblinks from Account'
rm -f src/main/default/objects/Account/webLinks/mcdm_15__*
echoOut 'removing mcdm_15__ weblinks from Lead'
rm -f src/main/default/objects/Lead/webLinks/mcdm_15__*
echoOut 'removing mcdm_15__ weblinks from Contact'
rm -f src/main/default/objects/Contact/webLinks/mcdm_15__*
echoOut 'Running ant doMetadataClean'
ant -buildfile build/build.xml doMetadataClean
echoOut 'Deploying static resources'
sfdx heber:staticresources:deploy -u $1
echoOut 'make a copy of .forceignore'
cp .forceignore .forceignore.orig
echoOut 'modifying .forceignore to not deploy staticresources or experiences'
echo -e "\nsrc/Base/main/default/staticresources" >> .forceignore
echo -e "\nsrc/BoatReservation/experiences" >> .forceignore
echo -e "\nsrc/CustomerCommunity/experiences" >> .forceignore
#echo -e "\nsrc/FactoryStoreSites/experiences" >> .forceignore
echo 'Deploying the remaining metadata'

if [ "$CHECKONLY" = true ]
then
  echoOut 'VALIDATING ONLY'
  if sfdx force:source:deploy --testlevel $TESTLEVEL --checkonly --targetusername $1 -p src/ -g -w 180 ; then
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
  else
    echoOut 'Validation Fail'
    exit 1
  fi
else
  if sfdx force:source:deploy --testlevel $TESTLEVEL --targetusername $1 -p src -g -w 180 ; then
    if [ $DEPLOY_EXPERIENCES = true ]
    then
      echoOut 're-enable original .forceignore'
      rm -f .forceignore
      mv .forceignore.orig .forceignore
      echoOut 'Deploying ExperienceBundles'
      sfdx force:source:deploy --testlevel NoTestRun --targetusername $1 -p src/BoatReservation/experiences -g -w 180
      sfdx force:source:deploy --testlevel NoTestRun --targetusername $1 -p src/CustomerCommunity/experiences -g -w 180
      sfdx force:source:deploy --testlevel NoTestRun --targetusername $1 -p src/FactoryStoreSites/experiences -g -w 180
    fi
  else
    echoOut 'Deploy Fail'
    exit 1
  fi
fi
