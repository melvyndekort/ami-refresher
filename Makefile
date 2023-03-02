.PHONY := clean build deploy
.DEFAULT_GOAL := build

ifndef AWS_SESSION_TOKEN
  $(error Not logged in, please run 'awsume')
endif

clean:
	@rm -rf \
	terraform/.terraform \
	terraform/.terraform.lock.hcl \
	terraform/lambda.zip \
	terraform/secrets.yaml

build:
	@IMAGE_ID=$$(docker image build -q src); \
	CONTAINER_ID=$$(docker container create $$IMAGE_ID); \
	docker container cp $$CONTAINER_ID:/tmp/lambda.zip terraform/lambda.zip; \
	docker container rm $$CONTAINER_ID

deploy: build
	@cd terraform; terraform init; terraform apply
