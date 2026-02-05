.PHONY: build up down restart logs shell cache-clear

COMPOSE = docker compose

build:
	$(COMPOSE) build

up:
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

restart:
	$(COMPOSE) restart

logs:
	$(COMPOSE) logs -f --tail=200

shell:
	$(COMPOSE) exec --user=www-data mautic_web bash

cache-clear:
	$(COMPOSE) exec --user=www-data mautic_web php /var/www/html/bin/console cache:clear --env=prod
