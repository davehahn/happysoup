#!/usr/bin/env bash

# Exit immediately if a any command exits with a non-zero status
# e.g. pull-request merge fails because of conflict
set -e

# Set destination branch
DEST_BRANCH=$1
BB_EXIT_CODE=$2
# get $BB_USER's uuid
BOSS="$(curl --user $BB_USER:$BB_PASSWORD https://api.bitbucket.org/2.0/user | jq -r '.uuid')"

JSON='{"title": "'$BITBUCKET_BRANCH' -> '$DEST_BRANCH'","description": "automatic PR from pipelines","state": "OPEN","destination": {"branch": {"name": "'$DEST_BRANCH'"}},"source": {"branch": {"name": "'$BITBUCKET_BRANCH'"}},"close_source_branch": true'

#echo "from $BITBUCKET_BRANCH to $DEST_BRANCH"
#echo "by $BITBUCKET_REPO_OWNER / $BITBUCKET_REPO_SLUG"
#echo "$BB_USER / $BB_PASSWORD"

# BB_EXIT_CODE will be 0 if the previous step succeeded
# so if it is anything other then 0 exit immediately
if [[ BB_EXIT_CODE -ne 0 ]]; then
  exit 1
fi

# if the boss started the pipeline step, close the JSON string else
# add the boss as a reviewer
if [ $BOSS == $BITBUCKET_STEP_TRIGGERER_UUID ]
then
  JSON2='}'
else
  JSON2=',"reviewers": [ { "uuid": "'$BOSS'" } ] }'
fi

PARAMS="$JSON$JSON2"

# Create new pull request
echo "Creating PR: $BITBUCKET_BRANCH -> $DEST_BRANCH"
curl -X POST https://api.bitbucket.org/2.0/repositories/$BITBUCKET_REPO_OWNER/$BITBUCKET_REPO_SLUG/pullrequests \
  --fail --show-error --silent \
  --user $BB_USER:$BB_PASSWORD \
  -H 'content-type: application/json' \
  -d "$PARAMS"