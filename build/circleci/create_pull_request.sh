#!/bin/bash

set -e

# Set destination branch
DEST_BRANCH=$1

echo "Creating PR: $GIT_BRANCH -> $DEST_BRANCH"
curl -X POST https://api.bitbucket.org/2.0/repositories/legend_devs/happysoup-sfdx/pullrequests \
  --fail --show-error --silent \
  --user $BB_USER:$BB_PASSWORD \
  -H 'content-type: application/json' \
  -d '{
    "title": "'$GIT_BRANCH' -> '$DEST_BRANCH'",
    "description": "automatic PR from pipelines",
    "state": "OPEN",
    "destination": {
      "branch": {
              "name": "'$DEST_BRANCH'"
          }
    },
    "source": {
      "branch": {
              "name": "'$GIT_BRANCH'"
          }
    },
    "close_source_branch": true
  }'
