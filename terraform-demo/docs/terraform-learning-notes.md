### Terraform Learning Notes

# Providers

Plugins enabling Terraform to interact with cloud providers such as AWS, where each provider defines what resources Terraform can manage.
It acts as a bridge between configuration code and real-world infrastructure.

# State

JSON file `terraform.tfstate` that is the source of truth mapping Terraform code to real-world infrastructure.
It describes resources, attributes, and dependencies necessary to build and maintain cloud resources. 

# Variables

Parameters used to customise Terraform modules without changing code. Ex: the region the resources will be created in can be set as a input variable, making the workflow dynamic.

# Resources 

Piece of infrastructure Terraform is going to build, like EC2 instance or security group. Resources are described as blocks.
Examples and attributes can be found in the official doc: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance

# Outputs

Printout information once the infrastructure has been built, useful for debugging.

# Commands

## terraform init

Initial command to set up Terraform in a repo, it downloads the provider set in the file, here AWS.

## terraform plan

Preview the infrastructure changes before they are applied. It generates an execution plan listing actions such as:
- creation `+`
- update `~`
- deletion `-`

## terraform apply 

Run the execution plan and create/update/delete cloud resources accordingly.

## terraform destroy

Reverse of `apply`, it dismantles all infrastructure defined in the configuration code.