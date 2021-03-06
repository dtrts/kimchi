# Kimchi

An example project of a complex service built in the AWS platform.
Goals:

- Multiple AWS services including lambdas, S3 buckets, SQSs, SNSs, dynamodb and more?
- Unit testing of node lambdas using Jest. Mocking calls to other AWS services.
- Have the service running in Localstack, with minimal affects to the code.
- Use Terraform.

## Installs

- [Homebrew](https://brew.sh/) (To install the rest)
- [Node](https://nodejs.org/en/)
- [Jest](https://jestjs.io/)
- [Docker](https://www.docker.com/)
- [Localstack](https://github.com/localstack/localstack)
- [awscli](https://aws.amazon.com/cli/)
- [awscli-local](https://github.com/localstack/awscli-local)

## AWS

For this example we will be using two accounts. One AWS proper, and one for local stack.
`$ aws configure --profile aws`
`$ aws configure --profile localstack` - Enter in dummy values here.

Multiple AWS accounts can be set up. Set the AWS_PROFILE environment variable when using the aws cli to replace adding `--profile aws` to every command.

## Localstack

Localstack

## Terraform

[Terraform](https://www.terraform.io/) is infrastructure as code.

Be a legend, `$ terraform -install-autocomplete`

Localstack requires Endpoint configuration.
This project uses the default endpoints and uses the provider configuration from the bottom of this article. https://www.terraform.io/docs/providers/aws/guides/custom-service-endpoints.html

### Workspaces

Since we will be building resources in multiple environments the state of each environment needs to be held separately.
This is achieved using [workspaces](https://www.terraform.io/docs/state/workspaces.html)

`$ terraform workspace new aws` - If using multiple aws accounts, create a workspace for each.
`$ terraform init aws`
`$ terraform workspace new localstack`
`$ terraform init localstack`

### Folder structure

The core architecture is contained in a module, and specific connection parameters are held in relevant sub-folders.
aws/main.tf and localstack/main.tf each pull in the core module.
When running terraform commands add the foldername to use the relevant connection parameters.

```
.
├── aws
│   └── main.tf
├── localstack
│   └── main.tf
├── modules
│   └── core
│       ├── main.tf
│       └── variables.tf
```

### Example Usage

The following commands are run in .../kimchi/terraform

Update localstack resources:

- `terraform workspace select localstack`
- `terraform apply localstack`

Update singe aws resources:

- Note: aws/main.tf contains the profile attribute in the provider object.
- `terraform workspace select aws`
- `terraform apply aws`

Localstack has been restarted:

- `rm terraform.tf.state.d

Update two aws accounts using the environment variable:

- Note: aws/main.tf _does not_ contain the profile parameter.
- AWS config has been run for aws_1 and aws_2.
- `export AWS_PROFILE=aws_1`
- `terraform workspace select aws_1`
- `terraform apply aws`
- `export AWS_PROFILE=aws_2`
- `terraform workspace select aws_2`
- `terraform apply aws`

Update two aws accounts using terraform provider config:
Folder structure:

```
.
├── aws_1
│   └── main.tf
├── aws_2
│   └── main.tf
├── localstack
│   └── main.tf
├── modules
│   └── core
│       ├── main.tf
│       └── variables.tf
```

- `terraform workspace select aws_1`
- `terraform apply aws`
- `terraform workspace select aws_2`
- `terraform apply aws`

### Notes

The localstack variable in the lambdas could be determined by the workspace name using something like: `localstack = "${terraform.workspace == "localstack" ?"true" : "false"}"`
I have left the variable to be defined in `terraform/{workspacename}/main.tf` for flexibility.

If localstack is restarted, the default is to destroy all resources, potentially butting the terraform state out of date. `rm -rf ./terraform/terraform.tfstate.d/localstack` to refresh.

## Lambda

The example here references the lambda code by zip file. If the zip file is updated and terraform is applied to the environment, terraform will update the code since the hash has changed.

### Deploying

Once you're ready to deploy, navigate to the lambda folder. Lambda-1 has an npm script to create the zip file. `npm run-script build`. Then run terraform the standard way, or using `make update-localstack`.

### Warning:

When accessing localstack s3 the current work around i have found uses the docker ip, not the localstack hostname variable. If you are running multiple containers, you will have to manually update that ip in the code.
TODO: Find a solution for this.

## Links

https://serverless.com/blog/unit-testing-nodejs-serverless-jest/

## Tips

Getting logs:

- aws logs describe-log-groups
- aws logs describe-log-streams --log-group-name
- aws logs get-log-events --log-group-name <log-group-name> --log-stream-name <log-steam-name>
- NOTE: Any \$ signs in the group or stream name needs to be escaped.

Filtering Results:

- The `--query` option allows you to filter results. The specification is here: http://jmespath.org/
- Get latest Stream `aws logs describe-log-streams --log-group-name /aws/lambda/kimchi-1-ingest-file --query 'sort_by(logStreams, &creationTime)[-1].logStreamName' --output text`

```
export LAMBDA_NAME=kimchi-1-ingest-file
export LATEST_STREAM=$(aws logs describe-log-streams --log-group-name /aws/lambda/${LAMBDA_NAME} --query 'sort_by(logStreams, &creationTime)[-1].logStreamName' --output text)
aws logs get-log-events --log-group-name /aws/lambda/kimchi-1-ingest-file --log-stream-name \$LATEST_STREAM --query events[*].message --output text
```
