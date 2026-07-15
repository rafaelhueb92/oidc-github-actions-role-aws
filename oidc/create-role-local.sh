AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)
GITHUB_REPO_NAME=$(basename $(dirname $(pwd)))
GITHUB_REPO="$GIT_HUB_USER_NAME/$GITHUB_REPO_NAME" # use in terminal => export GIT_HUB_USER_NAME="<Your-GIT-User"
GITHUB_ACTION_ROLE_NAME=GitHubActionsRole-$GITHUB_REPO_NAME
GITHUB_ACTION_POLICY_NAME=GitHubActionsPolicy-$GITHUB_REPO_NAME

RESPONSE=$(curl -s https://api.github.com/repos/$GITHUB_REPO)
OWNER_LOGIN=$(echo $RESPONSE | jq -r '.owner.login // empty')
OWNER_ID=$(echo $RESPONSE | jq -r '.owner.id // empty')
OWNER_TYPE=$(echo $RESPONSE | jq -r '.owner.type // empty')
REPO_NAME=$(echo $RESPONSE | jq -r '.name // empty')
REPO_ID=$(echo $RESPONSE | jq -r '.id // empty')

if [ -z "$OWNER_LOGIN" ] || [ -z "$OWNER_ID" ] || [ -z "$OWNER_TYPE" ] || [ -z "$REPO_NAME" ] || [ -z "$REPO_ID" ]; then
  echo "Error: could not resolve repository metadata for $GITHUB_REPO from the GitHub API."
  echo "$RESPONSE"
  exit 1
fi

if [ "$OWNER_TYPE" != "User" ] && [ "$OWNER_TYPE" != "Organization" ]; then
  echo "Error: unexpected owner type '$OWNER_TYPE' for $GITHUB_REPO. Expected 'User' or 'Organization'."
  exit 1
fi

echo "AWS Account $AWS_ACCOUNT_ID"
echo "Repository $GITHUB_REPO"
echo "Owner Type: $OWNER_TYPE"
echo "AWS Role $GITHUB_ACTION_ROLE_NAME"

EXISTS=$(aws iam list-open-id-connect-providers | grep -c "token.actions.githubusercontent.com")

if [ "$EXISTS" -eq 0 ]; then

echo "Create the OIDC Provider"

aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com

fi

ROLE_EXISTS=$(aws iam get-role --role-name "$GITHUB_ACTION_ROLE_NAME" 2>&1)

if [[ "$ROLE_EXISTS" == *"NoSuchEntity"* ]]; then

echo "Creating the Trust Policy for the Github Repository $GITHUB_REPO to deploy into the AWS account ID $AWS_ACCOUNT_ID"

COMPLETE_GITHUB_REPO="$OWNER_LOGIN@$OWNER_ID/$REPO_NAME@$REPO_ID"

sed -e "s/AWS_ACCOUNT_ID/$AWS_ACCOUNT_ID/g" -e "s|GITHUB_REPO|$COMPLETE_GITHUB_REPO|g" trust-policy.json > trust-policy-temp.json

echo "Creating the role $GITHUB_ACTION_ROLE_NAME"

aws iam create-role \
    --role-name $GITHUB_ACTION_ROLE_NAME \
    --assume-role-policy-document file://trust-policy-temp.json \
    --no-cli-pager \
    --output json

fi

echo "Putting the policy into the role"

aws iam put-role-policy --role-name $GITHUB_ACTION_ROLE_NAME \
  --policy-name $GITHUB_ACTION_POLICY_NAME \
  --policy-document file://permission-policy.json \
  --no-cli-pager \
  --output json

aws iam get-role --role-name $GITHUB_ACTION_ROLE_NAME --query 'Role.Arn' --output text