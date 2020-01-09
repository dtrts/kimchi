SHELL := /bin/bash

# Refresh

update-localstack:
	cd terraform && terraform workspace select localstack && terraform apply localstack && cd ..

AWS_PROFILE=$(shell echo $$AWS_PROFILE)
update-aws:
	cd terraform && terraform workspace select aws && terraform apply aws && cd ..

# Build 

build-l1: 
	cd $(LAMBDA_NAME) && npm run-script build

# Test

BUCKET_NAME_AWS=$(shell aws      s3api list-buckets --query 'Buckets[?contains(@.Name,`kimchi`)]| [0].Name' --output text)
BUCKET_NAME_LS=$(shell  awslocal s3api list-buckets --query 'Buckets[?contains(@.Name,`kimchi`)]| [0].Name' --output text)

test-1-aws:
	aws s3 cp events/dataset-1.json s3://$(BUCKET_NAME_AWS)/upload/dataset-1.json

test-1-ls:
	awslocal s3 cp events/dataset-1.json s3://$(BUCKET_NAME_LS)/upload/dataset-1.json


# Logs
LAMBDA_NAME=l1-ingest-file

l1-log-dtrts: get-l-log-aws

LATEST_STREAM_AWS=$(subst $$,\$$,$(shell aws logs describe-log-streams --log-group-name /aws/lambda/$(LAMBDA_NAME) --query 'sort_by(logStreams, &creationTime)[-1].logStreamName' --output text))
LATEST_STREAM_LS=$(subst $$,\$$,$(shell awslocal logs describe-log-streams --log-group-name /aws/lambda/$(LAMBDA_NAME) --query 'sort_by(logStreams, &creationTime)[-1].logStreamName' --output text))
get-l-log-aws:
	aws logs get-log-events --log-group-name /aws/lambda/$(LAMBDA_NAME) --log-stream-name $(LATEST_STREAM_AWS) --query events[*].message --output text
get-l-log-ls:
	awslocal logs get-log-events --log-group-name /aws/lambda/$(LAMBDA_NAME) --log-stream-name $(LATEST_STREAM_LS) --query events[*].message --output text
