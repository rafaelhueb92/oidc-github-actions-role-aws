GITHUB_REPO_NAME=$(basename $(dirname $(pwd)))
GITHUB_REPO="$GIT_HUB_USER_NAME/$GITHUB_REPO_NAME" # use in terminal => export GIT_HUB_USER_NAME="<Your-GIT-User"
GITHUB_ACTION_ROLE_NAME=GitHubActionsRole-$GITHUB_REPO_NAME
GITHUB_ACTION_POLICY_NAME=GitHubActionsPolicy-$GITHUB_REPO_NAME

aws iam put-role-policy --role-name $GITHUB_ACTION_ROLE_NAME \
  --policy-name $GITHUB_ACTION_POLICY_NAME \
  --policy-document file://permission-policy.json \
  --no-cli-pager \
  --output json