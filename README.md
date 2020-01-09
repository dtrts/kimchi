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

## Terraform

[Terraform](https://www.terraform.io/) is infrastructure as code.

Be a legend, `$ terraform -install-autocomplete`

### Create workspaces:

Need separate workspaces to hold the state of each environment.

`$ terraform workspace new aws`
`$ terraform workspace new localstack`

Make a workspace for each aws profile.

### Folder structure

This is a at the level of ./terraform relative to the project folder.

Make a symbolic link to give the same structure to localstack and aws :
`cd terraform/localstack`
`ln -s ../main.tf main.tf`
`cd ../localstack`
`ln -s ../main.tf main.tf`

```
.
├── aws
│   ├── main.tf -> ../main.tf
│   ├── provider.tf
│   └── variables.tf
├── localstack
│   ├── main.tf -> ../main.tf
│   ├── provider.tf
│   └── variables.tf
├── main.tf
├──
```

The resource definition proper is held in `./terraform/main.tf`

There is the option here to make a folder for each aws profile and set the profile name in the provider.tf file
OR
Have a single aws folder and set the aws account profile in the env variable.

### Update resources:

Long:
`<name>` here is either localstack or aws

`$ terraform workspace select <name>`
`$ terraform plan <name>`
`$ terraform apply <name>`

Short:
`$ make update-ls`
`$ make update-aws`

## Lambda

The example here references the lambda code by zip file. If the zip file is updated and terraform is applied to the environemnt, terraform will update the code since the hash has changed,

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
- Get latest Stream `aws logs describe-log-streams --log-group-name /aws/lambda/l1-ingest-file --query 'sort_by(logStreams, &creationTime)[-1].logStreamName' --output text`

- `export LAMBDA_NAME=l1-ingest-file`
- `export LATEST_STREAM=$(aws logs describe-log-streams --log-group-name /aws/lambda/${LAMBDA_NAME} --query 'sort_by(logStreams, &creationTime)[-1].logStreamName' --output text)`
- `aws logs get-log-events --log-group-name /aws/lambda/l1-ingest-file --log-stream-name \$LATEST_STREAM --query events[*].message --output text`
