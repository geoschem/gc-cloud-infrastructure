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