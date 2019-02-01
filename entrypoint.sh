#!/bin/bash

SYNC_DIR="${SYNC_DIR:=/sync-dir}"

function die {
    echo >&2 "$@"
    exit 1
}

if [ -z "${GIT_REPO_URL}" ]; then
  die "GIT_REPO_URL must be specified!"
fi
# Default to appkey
SSH_PK_ID_FILE="${SSH_PK_ID_FILE:-appkey}"
if [ ! -f "/root/.ssh/${SSH_PK_ID_FILE}" ]; then
  die "File not found: /root/.ssh/${SSH_PK_ID_FILE} .  Create a secret and mount that secret as a volume here."
fi
if [ ! -f "/root/.ssh/config" ]; then
  die "File not found: /root/.ssh/config .  Create a secret and mount that secret as a volume here."
fi

# branch default
GIT_REPO_BRANCH=${GIT_REPO_BRANCH:=master}

# Use default push behavior of Git 2.0
git config --global push.default simple

echo "$(date -R)"

if [ ! -d "${SYNC_DIR}/.git" ]; then
  echo "${SYNC_DIR} does not exist or is not a directory. Performing initial clone."
  git clone "${GIT_REPO_URL}" --branch "${GIT_REPO_BRANCH}" --single-branch "${SYNC_DIR}" || die "git clone failed"
  GIT_CLONED=1
else
  cd "${SYNC_DIR}"
  git pull origin "${GIT_REPO_BRANCH}" || die "git pull failed"
fi



chown -R 0:"${GROUP_ID:=999}" .
chmod -R 0640 .
find . -type d -print0 | xargs -0 chmod 775

CHANGED_FILES="$(git diff-tree -r --name-only --no-commit-id HEAD@{1} HEAD)"

# mount this to an empty_dir{} on the pod to cache results for doing build stuff in the next initContainer
if [ -d "/init_git_pull" ]; then

cat >/init_git_pull/result <<EOJ
#!/bin/bash

GIT_CLONED="${GIT_CLONED}"
read -r -d '' CHANGED_FILES <<EOL
${CHANGED_FILES}
EOL

check_run() {
  echo "$CHANGED_FILES" | grep -E --quiet "$1" && eval "$2"
}

EOJ

fi
