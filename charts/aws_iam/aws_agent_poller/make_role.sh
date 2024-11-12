#!/bin/bash

if [ -z "$1" ]; then
    PROFILE="default"
else
    PROFILE=$1
fi



echo "Using profile $PROFILE"
echo "Creating role"
aws  --profile $PROFILE iam create-role \
--role-name spyderbat-aws-agent-poller-role \
--assume-role-policy-document file://trust_policy.json

echo "Adding permissions"
aws  --profile $PROFILE iam put-role-policy \
    --role-name spyderbat-aws-agent-poller-role \
    --policy-name spyderbat-aws-agent-poller-permissions \
    --policy-document file://permissions.json

echo "All done"