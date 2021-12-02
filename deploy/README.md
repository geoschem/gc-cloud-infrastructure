# gc-cloud-infrastructure
This repository is used for the automation and deployment of aws infrastructure to the cloud
## Projects this repository handles
- aws infrastructure related to the automation of GCClassic and GCHP benchmarks
- infrastructure for syncing input data to the cloud

## Setting up your development environment
## Pre-requisites

- [Terraform 1.0.5](https://www.terraform.io/downloads.html)
  - Use this specific version, 1.0.5.
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)
  - Install on your local machine, instructions are available on [readthedocs](https://cloud-gc.readthedocs.io/en/latest/chapter02_beginner-tutorial/awscli-config.html)
### Installing terraform
We are leveraging [terraform](https://www.terraform.io/) for the creation and management of our aws infrastructure related to benchmarking. Follow the following steps to install terraform:
1. Install [tfswitch](https://tfswitch.warrensbox.com/) to easily manage the version of terraform installed. Unfortunately, tfswitch does not have windows support, so if using windows follow the terraform download instructions [here](https://www.terraform.io/downloads.html) (make sure to download the correct version). 

    On macOS:
    ```bash
    > brew install warrensbox/tap/tfswitch
    ```
    On Linux:
    ```bash
    > curl -L https://raw.githubusercontent.com/warrensbox/terraform-switcher/release/install.sh | bash
    ```
2. Install the correct version of terraform:
```bash
> tfswitch 1.0.5 
```
Note: you may need to add terraform to your PATH
### Usage

### Before Invoking Terraform

Before you invoke any Terraform command use the AWS CLI to login to your organization.

```bash
  aws configure
```

You will be prompted for `AWS Access Key ID`, `AWS Secret Access Key`, `Default region name`, and `Default output format`. For the first two use the specific keys assigned to you as part of your active AWS organization. For the latter two you can use `us-east-1` and `json`.

### Applying recipes to a given environment

To apply the most recent terraform recipes to an environment run the following ...

```bash
  $ cd deploy/environments/harvard       # or the washu directory
  $ terraform init                       # installs all the necessary modules and plugins for this environment
  $ terraform plan                       # review the anticipated changes
  $ terraform apply                      # creates, updates, or destroys the planned resources on aws  
  $ git add . \                          # important since terraform keeps track of state using local files
    && git commit -m "applied updates to qa" \
    && git push
```

    
