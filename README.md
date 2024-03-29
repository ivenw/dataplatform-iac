# Introduction 
This repository contains the infrastructure-as-code for the data platform.

Stateful deployment is managed via terraform and we use terramate to
orchestrate different terraform deployment steps and increase DRYness of the
code where it makes sense.

## Project structure and patterns

To reduce the blast radius of individual deployments, we utilize the "stack"
concept introduced in terramate.

We utilize "modules" to encapsulate code that is re-used in multiple stacks.
With modules we strictly follow the role that modules should not be nested,
i.e. a module should not contain another module or call a module.

Instead, we make frequent use of the dependency injection pattern if a module requires
output of another module. For example, if a module would need the name and locaiont 
of a resource group, we would define the variable as follows:

"""terraform
variable "resource_group" {
  type = object({
    name     = string
    location = string
  })
}
"""

To work with modules that call other modules, we introduce the concept of "packages".
Most of the time a package contains the logic to create a deployment in different
environments.

# Development

Besides being used for stack orchestration, terramate is a terraform code generation
tool that transpiles HCL code to terraform. We find three types of files written in
HCL in the repo.

- `*.tf` / Normal terraform files
- `*.tm.hcl` / Terramate hcl files that either contain terramate configuration or
code generation logic
- `*.tm.tf` / Terraform files that have been generated by terramate (Note: the `.tm` file
ending here is just a convention to mark the files as generated)

## Prerequisites

- terraform cli
- terramate cli

## Making changes

All stacks are parametrized through the `globals.tm.hcl` file located in root. Any configuration
changes likely only have to be made here. For example, adding a new environment would happen exclusively here.
(In addition to creating the new stack).

If changes where made to a `.tm.hcl` file, it is important to run `terramate fmt` followed by
`terramate generate`.

If changes are made to a `.tf` file, it is important to run `terraform fmt -recursive`, as
propper formating is enforced in CI.

An additonal lint that is run is `terraform validate` so you may want to run that too.

## Deployment

If changes are limited to only one stack, it is ok to cd into the stacks directory and
run terraform commands from there. It is *highly* recommended to run `terraform plan`
before running `terraform apply` to ensure that no accidental and harmful changes are made
to the infrastructur.

If changes affect multiple stacks, we can utilize terramate to orchestrate the correct
order of applies (if there are dependencies between the stacks). Run `terramate run --changed /*tf command*/`,
where `/*tf command*/` is the terraform command you want to run.

