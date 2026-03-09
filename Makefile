SHELL := /bin/bash

.PHONY: lint check

lint:
	shellcheck setup.sh lib/*.sh scripts/*.sh
	yamllint compose/docker-compose.yml .github/workflows/ci.yml

check:
	bash -n setup.sh lib/*.sh scripts/*.sh
