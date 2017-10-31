
function ensure_credentials() {
    if [ -z "$AWS_SESSION_TOKEN" ]; then
        read -p "MFA > " mfa_code

        # All prod accounts require MFA in order to use them. get-session-token
        # exchanges an API key + mfa code for a temporary set of creds.
        credential_info=$(aws sts get-session-token \
            --duration-seconds 900 \
            --serial-number $AWS_MFA_ARN \
            --token-code $mfa_code
        )

        export AWS_ACCESS_KEY_ID=$(echo $credential_info | jq -r .Credentials.AccessKeyId)
        export AWS_SECRET_ACCESS_KEY=$(echo $credential_info | jq -r .Credentials.SecretAccessKey)
        export AWS_SESSION_TOKEN=$(echo $credential_info | jq -r .Credentials.SessionToken)
    fi
}

function assume_role_in_dev_account() {
    account_id=$1
    role_session_name=$2

    dev_account_cred_info=$(aws sts assume-role \
        --duration-seconds 900 \
        --role-session-name $role_session_name \
        --role-arn arn:aws:iam::${account_id}:role/OrganizationAccountAccessRole)
    export AWS_ACCESS_KEY_ID=$(echo $dev_account_cred_info | jq -r .Credentials.AccessKeyId)
    export AWS_SECRET_ACCESS_KEY=$(echo $dev_account_cred_info | jq -r .Credentials.SecretAccessKey)
    export AWS_SESSION_TOKEN=$(echo $dev_account_cred_info | jq -r .Credentials.SessionToken)
}

