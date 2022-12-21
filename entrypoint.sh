#!/bin/sh -l

set -e  # if a command fails it stops the execution
set -u  # script fails if trying to access to an undefined variable

echo "[+] Action start"
SOURCE_BEFORE_DIRECTORY="${1}"
SOURCE_DIRECTORY="${2}"
DESTINATION_GITHUB_USERNAME="${3}"
DESTINATION_REPOSITORY_NAME="${4}"
GITHUB_SERVER="${5}"
USER_EMAIL="${6}"
USER_NAME="${7}"
DESTINATION_REPOSITORY_USERNAME="${8}"
TARGET_BRANCH="${9}"
COMMIT_MESSAGE="${10}"
TARGET_DIRECTORY="${11}"

if [ -z "$DESTINATION_REPOSITORY_USERNAME" ]
then
	DESTINATION_REPOSITORY_USERNAME="$DESTINATION_GITHUB_USERNAME"
fi

if [ -z "$USER_NAME" ]
then
	USER_NAME="$DESTINATION_GITHUB_USERNAME"
fi

# Verify that there (potentially) some access to the destination repository
# and set up git (with GIT_CMD variable) and GIT_CMD_REPOSITORY
if [ -n "${SSH_DEPLOY_KEY:=}" ]
then
	echo "[+] Using SSH_DEPLOY_KEY"

	# Inspired by https://github.com/leigholiver/commit-with-deploy-key/blob/main/entrypoint.sh , thanks!
	mkdir --parents "$HOME/.ssh"
	DEPLOY_KEY_FILE="$HOME/.ssh/deploy_key"
	echo "${SSH_DEPLOY_KEY}" > "$DEPLOY_KEY_FILE"
	chmod 600 "$DEPLOY_KEY_FILE"

	SSH_KNOWN_HOSTS_FILE="$HOME/.ssh/known_hosts"
	ssh-keyscan -H "$GITHUB_SERVER" > "$SSH_KNOWN_HOSTS_FILE"

	export GIT_SSH_COMMAND="ssh -i "$DEPLOY_KEY_FILE" -o UserKnownHostsFile=$SSH_KNOWN_HOSTS_FILE"

	GIT_CMD_REPOSITORY="git@$GITHUB_SERVER:$DESTINATION_REPOSITORY_USERNAME/$DESTINATION_REPOSITORY_NAME.git"

elif [ -n "${API_TOKEN_GITHUB:=}" ]
then
	echo "[+] Using API_TOKEN_GITHUB"
	GIT_CMD_REPOSITORY="https://$DESTINATION_REPOSITORY_USERNAME:$API_TOKEN_GITHUB@$GITHUB_SERVER/$DESTINATION_REPOSITORY_USERNAME/$DESTINATION_REPOSITORY_NAME.git"
else
	echo "::error::API_TOKEN_GITHUB and SSH_DEPLOY_KEY are empty. Please fill one (recommended the SSH_DEPLOY_KEY)"
	exit 1
fi

echo "[+] Git version"
git --version

echo "[+] Cloning destination git repository $DESTINATION_REPOSITORY_NAME"
# Setup git
git config --global user.email "$USER_EMAIL"
git config --global user.name "$USER_NAME"

echo "[+] Listing Current Directory Location"
ls -al
echo "[+] set safe.directory"
git config --global --add safe.directory /github/workspace
git fetch --unshallow origin
echo "[+] Show current origin"
git remote -v
# echo "[+] Delete origin"
# git remote rm origin
# echo "[+] Show current origin"
# git remote -v
echo "[+] Add origin"
git remote add destination_origin $GIT_CMD_REPOSITORY
echo "[+] Show current origin"
git remote -v

echo "[+] Pushing git commits"
git push destination_origin ${GITHUB_REF##*/}:$TARGET_BRANCH
