# docker-git-sync
A docker image allowing you to sync a folder with a git repository.

To use it, you must pass the following **environment variables**:

* `GIT_REPO_URL`: URL of the Git repository to sync to, for example `ssh://git@example.com/foo/bar.git`. (required)
* `GIT_REPO_BRANCH`: Branch of the Git repository to sync to, for example `production`. Defaults to `master`.
* `SYNC_DIR`: path to pull contents into.  Should match your mounted directory path.  (defaults to `/sync-dir`)
* `GROUP_ID`: (defaults to 999); after clone/pull, the sync dir is chmod'd to  0:$GROUP_ID
* `SSH_PK_ID_FILE`: name of private key file. This should be a mounted secret along with a `config` file at the same location. (defaults to `appkey`). e.g.

```sh
Host bitbucket.org
    IdentityFile /root/.ssh/appkey
    User chloeId
    StrictHostKeyChecking no
```
