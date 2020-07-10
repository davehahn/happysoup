#!/bin/bash

USER="$(cat $BITBUCKET_CLONE_DIR/org_info.json | jq -r '.username')"
sfdx sfpowerkit:auth:login -u $USER --password $1 -a ci-static-res
sfdx heber:staticresources:deploy -u ci-static-res

