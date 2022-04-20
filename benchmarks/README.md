# Batch Benchmarking workflow
The items in this directory are intended for an automated benchmarking workflow on the cloud. All AWS infrastructure code is contained in the top level deploy directory. This directory contains the rest (eg. Dockerfiles, automation scripts, etc.).

Benchmarks are triggered by github actions in the [GCClassic](https://github.com/geoschem/GCClassic/tree/dev) and [GCHP](https://github.com/geoschem/GCHP/tree/dev) repositories, but you can trigger cloud benchmarks manually as well (see below for details).
### Deploying the dockerfile to ecr
1. `$ aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 753979222379.dkr.ecr.us-east-1.amazonaws.com`
2. `$ docker build -t benchmarks-cloud-repository .`
3. `$ docker tag benchmarks-cloud-repository:latest 753979222379.dkr.ecr.us-east-1.amazonaws.com/benchmarks-cloud-repository:latest`
4. `$ docker push 753979222379.dkr.ecr.us-east-1.amazonaws.com/benchmarks-cloud-repository:latest`

### SSH into a batch job
- when creating the job specify runForever.sh as the entrypoint
- ssh command:
`$ ssh -i "lestrada_keypair.pem" ec2-user@public-ip`
- exec into docker container:
`$ docker exec -it <docker-image-id> bash`

### Running an automated benchmark via step functions
1. Log onto the aws console and navigate via the search bar to 'Step Functions' Service
1. Go to State Machines > benchmarks-cloud-workflow
1. Click "Start Execution" and enter in the following json replacing values for your needs
The input data format for step functions is the following:
```
{
    "event": {
        "nameSuffix": "28c9b26",  // can't use tag because punctuation is not accepted
        "primaryKey": "gchp-24-1Hr-13.4.0-alpha.27-2-g28c9b26",
        "simulationType": "gchp", // or gcc
        "runType": "SPOT", // or DEMAND
        "timePeriod": "1Hr", // or 1Mon/1Day
        "tag": "28c9b26", // accepts tags, branch names, or commits
        "numCores": "62", // number of cores to deploy with
        "memory": "80000", // amount of memory to deploy with
        "resolution": "24", // resolution to run at (GCHP only)
        "sendEmailNotification": "true", // optional parameter, send email notifications of status
        "skipCreateRunDir": "true" // optional parameter, skips creating run directory
    },
    "plotting": { // optional section, if plotting desired
        "devPrimaryKey": "gchp-24-1Hr-13.4.0-alpha.27-2-g28c9b26", // primary key for dev
        "refPrimaryKey": "gchp-24-1Hr-13.4.0-alpha.26-1-g35edefe" // primary key for ref
    }
}
```
Note: you must remove the comments before submitting
1. Once started, you can monitor the progress of the overall workflow via the step function visualization
1. Progress of individual steps can be monitored via cloudwatch in the /aws/batch/benchmarks-cloud log group