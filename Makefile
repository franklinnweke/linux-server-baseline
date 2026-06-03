SHELL := /bin/bash

.PHONY: lint check validate-nginx

lint:
	shellcheck setup.sh lib/*.sh scripts/*.sh
	yamllint compose/docker-compose.yml .github/workflows/ci.yml .yamllint.yml

check:
	bash -n setup.sh lib/*.sh scripts/*.sh

validate-nginx:
	DOMAIN=example.com APP_PORT_INTERNAL=5678 envsubst '$${DOMAIN} $${APP_PORT_INTERNAL}' < nginx/site.conf.template > /tmp/linux-server-baseline-site.conf
	printf 'events {}\nhttp { include /tmp/linux-server-baseline-site.conf; }\n' > /tmp/linux-server-baseline-nginx.conf
	nginx -t -c /tmp/linux-server-baseline-nginx.conf -p /tmp
