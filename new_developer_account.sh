#!/bin/bash -e
# This script will create a new AWS account for a developer. Best practice
# suggests that developers don't get root accounts. So we don't deal with the
# root account at all. The account is created by aws organizations which drops
# a role in there that trusts our main payer account. We then assume that role
# and configure an IAM user in there with a random password and print out
# sample email text to give to the new account user.
# TODO: Move the account into the engineering OU in organizations.

. lib.sh

userid=$1
domain=$2
if [ -z "$userid" -o -z "$domain"]; then
    echo "Usage: $0 <userid> <domain>"
fi

ensure_credentials

account_create_result=$(aws --region us-east-1 organizations create-account \
    --email aws-dev+$userid@$domain \
    --account-name $userid \
    --role-name OrganizationAccountAccessRole
)
state=$(echo $account_create_result | jq -r .CreateAccountStatus.State)
request_id=$(echo $account_create_result | jq -r .CreateAccountStatus.Id)

echo "Account in creating state with request id: $request_id"

# TODO this loop will go forever if the account enters a failed state. That
# said, the user can ^c it.
while [ "$state" != "SUCCEEDED" ]; do
    sleep 5
    account_status=$(aws --region us-east-1 organizations describe-create-account-status \
      --create-account-request-id $request_id)
    echo "$account_status"
    state=$(echo $account_status | jq -r .CreateAccountStatus.State)
    reason=$(echo $account_status | jq -r .CreateAccountStatus.FailureReason)
    echo "Account creation status is: $state: $reason"
done

account_id=$(echo $account_status | jq -r .CreateAccountStatus.AccountId)
echo "Account id is: $account_id"

echo "Pausing to let things propagate within AWS."
sleep 10

assume_role_in_dev_account $account_id account-creator
aws iam create-user --user-name $userid
echo "User created."
sleep 1

aws iam attach-user-policy --user-name $userid --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
echo "User promoted to admin."
sleep 1

temp_password=$(python -c "import uuid; print uuid.uuid4().hex")
aws iam create-login-profile --user-name $userid \
          --password $temp_password \
          --password-reset-required

echo "Login at https://$account_id.signin.aws.amazon.com/console"
echo "Username: $userid Password: $temp_password"
echo "You will be forced to change your password on first login. Please enable MFA."
