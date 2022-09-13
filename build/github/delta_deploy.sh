#!/bin/bash
ID=""
STATUS=""
ISDONE=false
ISSUCCESS=false
COMPONENTS=0
COMPONENTS_DEPLOYED=0
TESTS=0
TESTS_COMPLETE=0
DEPLOYER='ci-deploy'

_sourcePath=${1}
_testLevel=${2}
_apexTests=${3}

function ProgressBar {
  # Process data
  let _progress=(${1}*100/${2}*100)/100
  let _done=(${_progress}*4)/10
  let _left=40-$_done
  # Build progressbar string lengths
  _done=$(printf "%${_done}s")
  _left=$(printf "%${_left}s")

  # 1.2 Build progressbar strings and print the ProgressBar line
  # 1.2.1 Output example:
  # 1.2.1.1 Progress : [########################################] 100%
  printf "\rDEPLOY PROGRESS : [${_done// /#}${_left// /-}] ${1}/${2} Components"
}

function OutputProgress {
  _total=$(($COMPONENTS))
  _done=$(($COMPONENTS_DEPLOYED))
  if [[ $_total -gt 0 ]]; then
    ProgressBar ${_done} ${_total}
  fi
  if $ISDONE; then
    ProgressBar ${_total} ${_total}
    if $ISSUCCESS; then
      echo ''
      echo ''
      echo 'We are Done!!!!'
      echo ''
      sfdx force:mdapi:deploy:report -u $DEPLOYER -i $ID
    else
      ProgressBar ${_total} ${_total}
      echo ''
      echo ''
      echo "DEPLOY FAILED !!!!"
      sfdx force:mdapi:deploy:report -u $DEPLOYER -i $ID --verbose
    fi
  else
    sleep 1
    GetProgress
  fi
}

function GetProgress {
  echo $(sfdx force:mdapi:deploy:report -u $DEPLOYER -i $ID --json) > result.json
  _resultJSON=$(node build/github/readJson.js)
  STATUS=$(jq -n "$_resultJSON" | jq '.status')
  ISDONE=$(jq -n "$_resultJSON" | jq '.isDone')
  ISSUCCESS=$(jq -n "$_resultJSON" | jq '.isSuccess')
  COMPONENTS=$(jq -n "$_resultJSON" | jq '.numOfComponents')
  COMPONENTS_DEPLOYED=$(jq -n "$_resultJSON" | jq '.numOfComponentsDeployed')
  OutputProgress
  #_done=$(sfdx force:mdapi:deploy:report -u ci-deploy -i $ID --json | jq '.result.done' )
  # if [[ -z $1 ]] || [[ "${_done}" == "null" ]]; then
  #   echo "_done is null"
  #   sleep 1
  #   GetProgress
  # else
    # if $_done; then
    #   ISSUCCESS=$(sfdx force:mdapi:deploy:report -u ci-deploy -i $ID --json | jq '.result.success' )
    #   OutputProgress
    # else
    #   REPORT=$(sfdx force:mdapi:deploy:report -u ci-deploy -i $ID --json | jq '.result' )
    #   if [[ "${REPORT}" == "null" ]]; then
    #     echo "deploy report is null"
    #     sleep 1
    #     GetProgress
    #   else
    #     STATUS=$(jq -n "$REPORT" | jq '.status')
    #     ISDONE=$(jq -n "$REPORT" | jq '.done')
    #     ISSUCCESS=$(jq -n "$REPORT" | jq '.success')
    #     COMPONENTS=$(jq -n "$REPORT" | jq '.numberComponentsTotal')
    #     COMPONENTS_DEPLOYED=$(jq -n "$REPORT" | jq '.numberComponentsDeployed')
    #     TESTS=$(jq -n "$REPORT" | jq '.numberTestsTotal')
    #     TESTS_COMPLETE=$(jq -n "$REPORT" | jq '.numberTestsCompleted')
    #     OutputProgress
    #   fi
    # fi
  # fi
}

function Deploy {
  if [[ "$_testLevel" == "RunSpecifiedTests" ]]; then
    _result=$(sfdx force:source:deploy -p $_sourcePath --testlevel $_testLevel -r $_apexTests -u $DEPLOYER -w 0 --json 2> /dev/null | jq '.result')
  else
    _result=$(sfdx force:source:deploy -p $_sourcePath --testlevel $_testLevel -u $DEPLOYER -w 0 --json 2> /dev/null | jq '.result')
  fi
  ID=$(jq -n "$_result" | jq -r '.id')
  echo "Deploy Id = ${ID}"
  GetProgress
}

Deploy