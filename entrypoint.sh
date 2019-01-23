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

if [ ! -d "$SYNC_DIR" ]; then
  echo "${SYNC_DIR} does not exist or is not a directory. Performing initial clone."
  git clone "${GIT_REPO_URL}" --branch "${GIT_REPO_BRANCH}" --single-branch "${SYNC_DIR}" || die "git clone failed"
  GIT_CLONED=1
elif [ ! -d "$SYNC_DIR/.git" ]; then
  echo "${SYNC_DIR} exists but does not contain a git repository. Clean out all existing files and initiale local git repository before pulling remote."
  cd "${SYNC_DIR}"; find -delete 

  if [ -n "$(ls -A ${SYNC_DIR})" ]; then
    die "${SYNC_DIR} is still not empty. 'find -delete' failed"
  fi

  git init || die "git init failed"
  git remote add origin "${GIT_REPO_URL}" || die "git remote add failed"
  git fetch origin "${GIT_REPO_BRANCH}" || die "git fetch failed"
  git checkout -t "origin/${GIT_REPO_BRANCH}" || die "git checkout failed"
fi

cd "${SYNC_DIR}"
git pull origin "${GIT_REPO_BRANCH}" || die "git pull failed"
chown -R 0:"${GROUP_ID:=999}" .
chmod -R 0640 .
find . -type d -print0 | xargs -0 chmod 775

