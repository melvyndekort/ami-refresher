.PHONY := apply
.DEFAULT_GOAL := apply

ifndef AWS_SESSION_TOKEN
  $(error Not logged in, please run 'awsume')
endif

apply:
	@cd terraform; terraform init; terraform apply
