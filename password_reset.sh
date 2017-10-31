#!/bin/bash -e

. lib.sh

userid=$1
if [ -z "$userid" ]; then
    echo "Usage: $0 <userid> <accountid>"
    exit 1
fi

account_id=$2
if [ -z "$account_id" ]; then
    echo "Usage: $0 <userid> <accountid>"
    exit 1
fi

ensure_credentials

assume_role_in_dev_account $account_id reset-password

temp_password=$(python -c "import uuid; print uuid.uuid4().hex")
echo "New password will be $temp_password"
aws iam update-login-profile --user-name $userid --password $temp_password --password-reset-required
