# Creating new Datacube WMS stack

## Software Requirements
* Terraform >= 0.10.0
* Docker

### Software Requirements for Secret Storage with Chamber
* golang development packages
* segment.io Chamber
* (Optional) AWS Vault

## AWS Requirements
* s3 bucket for storing Terraform state
* DynamoDB table for storing Terraform lock
* KMS Key with alias `parameter_store_key`

## Docker Image
We recommend you use geoscienceaustralia/datacube-wms:latest from Docker Hub.

## Using Chamber to store secrets
All secrets e.g. passwords should be stored encrypted in AWS. Chamber For simple secrets management and retrieval. To create and update a new secret in chamber you will need to be authenticated with AWS and have permission to read and write to the SSM. On a development machine we recommend using AWS Vault to manage authentication. To create or update a secret `chamber write service key value`

### Writing DB Password
As an example we will add a DB Password to the `datacube-wms` service - `chamber write datacube-wms db_password Password1`. For a different project change the name of the service.
 
## Setup Infrastructure
The Datacube WMS infrastructure is defined in `main.tf` using `variables.tf`. The default collection of modules used will create:
* A VPC
* An Elastic Container Service, running the WMS docker image as a task
* An EC2 Autoscaling Group
* An ALB
* A RDS instance
* IAM roles, policies, and users for the above
* Public and Private subnets to manage the above

In order to create a new stack the following changes should be made in `main.tf`
* In the `terraform` block modify the `key` to be a string unique to your project.
* If you are using a custom Docker image set the `name` inside `"docker_registry_image" "latest"`
* Set or create `cluster` to a unique name for your VPC cluster.
* Set or create `workspace` to a unique name for your WMS stack. This name will be used as a namespace for many of the parts of your stack.
* Set or create the `task_desired_count` to the number of ECS tasks required to run.
* Set `enable_jumpbox` to true for SSH access to your EC2 instances.
* If `enable_jumpbox` was set true above, set or create `key_name` to the name of an AWS key pair you would like to use to SSH into your EC2 instances.
* In the `ec2_instances` module set the `instance_type`, `max_size`, `min_size`, and `desired_capacity`.
## Import Existing State
Terraform maintains its own AWS state and it will not automatically attempt to reconcile this with the true AWS state. For a new setup of Datacube WMS the only existing AWS state needed is the KMS key for secrets. If using the default setup:
* Find the ARN of `parameter_store_key` using AWS CLI or AWS Web Console
* Run `terraform import module.ecs_policy.aws_kms_key.parameter_store_key ARNHERE`

## Plan and Run Terraform
* `terraform plan -out wms.plan`
* Sanity check the output of the plan. If this is a new stack, resources should only be created and not destroyed or modified.
* `terraform apply wms.plan`parameter_store_key

## Destroying Infrastructure
* The `parameter_store_key` must be forgotten by Terraform before destruction. If not forgotten it will be marked for deletion which risks losing all data encrypted with the key. Assuming default setup - `terraform state rm module.ecs_policy.aws_kms_key.parameter_store_key`
* Run `terraform destroy` and confirm destruction.