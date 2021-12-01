# Batch Benchmarking workflow
The items in this directory are intended for an automated benchmarking workflow on the cloud. All AWS infrastructure code is contained in the top level deploy directory. This directory contains the rest (eg. Dockerfiles, automation scripts, etc.)
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

### Running a benchmark step function
The input data format for step functions is the following:
```
{
    "event": {
      "nameSuffix": "{commit-hash?}",
      "runType": "GCC", # or GHCP
      "tag": "13.2.1",  # accepts tags, branch names, or commits
      "numCores": "48", # number of cores to deploy with
      "memory": "16000" # amount of memory to deploy with
      "resolution": "24" # resolution to run at (GCHP only)
    }
}
```