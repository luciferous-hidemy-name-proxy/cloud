SHELL = /usr/bin/env bash -xeuo pipefail

format: \
	fmt-python \
	fmt-terraform

fmt-python: \
	fmt-python-isort \
	fmt-python-black

fmt-python-isort:
	poetry run isort --profile black src/ tests/

fmt-python-black:
	poetry run black src/ tests/

fmt-terraform: \
	fmt-terraform-root \
	fmt-terraform-common \
	fmt-terraform-lambda-function-basic \
	fmt-terraform-lambda-function

fmt-terraform-root:
	terraform fmt

fmt-terraform-common:
	cd terraform_modules/common && \
	terraform fmt

fmt-terraform-lambda-function-basic:
	cd terraform_modules/lambda_function_basic && \
	terraform fmt

fmt-terraform-lambda-function:
	cd terraform_modules/lambda_function && \
	terraform fmt

test-unit:
	AWS_ACCESS_KEY_ID=dummy \
	AWS_SECRET_ACCESS_KEY=dummy \
	AWS_DEFAULT_REGION=ap-northeast-1 \
	PYTHONPATH=src/handlers:src/layers/common/python \
	poetry run pytest -vv tests/unit

.PHONY: \
	format \
	fmt-python \
	fmt-python-isort \
	fmt-python-black \
	fmt-terraform \
	fmt-terraform-root \
	fmt-terraform-common \
	fmt-terraform-lambda-function-basic
