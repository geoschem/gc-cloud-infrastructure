# Backend-Readme
The backend directory handles creating the necessary infrastructure needed to store your tfstate files on the cloud. Be very careful modifying anything here. This should be a place one person terraform applies from once and nobody touches thereafter. If you do make changes make sure to commit your terraform state files to version control.
Note: there are two terraform projects in this repository 99% of the time you will want the other one (one directory above this one). Ask Lucas if you aren't sure.
## First time setup
If you are the first one to use this repository in your aws account then you should run the following:
```bash
  $ cd deploy/environments/washu/backend
  $ terraform init                       # installs all the necessary modules and plugins for this environment
  $ terraform plan                       # review the anticipated changes
  $ terraform apply                      # creates, updates, or destroys the planned resources on aws  
  $ git add . \                          # important since terraform keeps track of state using local files
    && git commit -m "created terraform backend for harvard" \
    && git push
```

This will create the following artifacts:
- an s3 bucket with versioning set to true for your tfstate files
- an dynamodb table that is used to acquire a lock before terraform applying
