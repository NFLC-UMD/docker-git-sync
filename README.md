# init-git-pull
A docker image designed as a k8 initContainer for git pull on pod initialization.

To use it, you must pass the following **environment variables**:

* `GIT_REPO_URL`: URL of the Git repository to sync to, for example `ssh://git@example.com/foo/bar.git`. (required)
* `GIT_REPO_BRANCH`: Branch of the Git repository to sync to, for example `production`. Defaults to `master`.
* `SYNC_DIR`: path to pull contents into.  Should match your mounted directory path.  (defaults to `/sync-dir`)
* `GROUP_ID`: (defaults to 999); after clone/pull, the sync dir is chmod'd to  0:$GROUP_ID
* `SSH_PK_ID_FILE`: name of private key file. This should be a mounted secret along with a `config` file at the same location. (defaults to `appkey`). See below.

## Setup
1. Create and get your app service account private key (i.e. deployment ssh keys) defined for your repo. For more info see: (https://confluence.atlassian.com/bitbucket/access-keys-294486051.html).  Name it `appkey` and place it in tmp folder.
2. Create `config` file. Replace `<myappId>` with the name of your app service account defined above. 
```sh
Host example.com
    IdentityFile /root/.ssh/appkey
    User <myappId>
    StrictHostKeyChecking no
```
3. Create ssh-appkey secret:
```
kubectl create secret generic ssh-appkey 
        --from-file=config=/path/to/config \
        --from-file=appkey=/path/to/appkey
```
1. Example of how to use in a kubernetes deployment manifest
```yaml
    volumes:
    - name: myapp-api-pvc
        persistentVolumeClaim:
            claimName: myapp-api-source-code-pvc
    - name: sshkey
        secret:
            secretName: ssh-appkey
            defaultMode: 256
    initContainers:
    - name: git-sync
        image: init-git-pull
        volumeMounts:
        - name: sshkey
            mountPath: "/root/.ssh"        
        - name: myapp-pvc
            mountPath: /sync-dir
            subPath: api
        env:
        - name: GIT_REPO_URL
            value: ssh://git@github.com/myorg/myapprepo.git
        - name: GIT_REPO_BRANCH
            value: myworkbranch
    containers:
    - name: myapp
        image: repo/imagename
            volumeMounts:
            - name: myapp-api-pvc
                mountPath: /some/path
                subPath: api
```


