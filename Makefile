SHELL = /usr/bin/env bash -xeuo pipefail

format: \
	fmt-terraform

fmt-terraform: \
	fmt-terraform-root \
	fmt-terraform-common \
	fmt-terraform-lambda-function-basic

fmt-terraform-root:
	terraform fmt

fmt-terraform-common:
	cd terraform_modules/common && \
	terraform fmt

fmt-terraform-lambda-function-basic:
	cd terraform_modules/lambda_function_basic && \
	terraform fmt

.PHONY: \
	format \
	fmt-terraform \
	fmt-terraform-root \
	fmt-terraform-common \
	fmt-terraform-lambda-function-basic
