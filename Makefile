BRANCH ?= $(shell git rev-parse --abbrev-ref HEAD | tr -d '\n')

.PHONY: prod rubocop spec vagrant

prod:
	bundle exec cap production deploy

rubocop:
	rubocop --format simple --config .rubocop.yml --auto-correct

spec:
	CI=1 RAILS_ENV=test bundle exec rake ci --trace

vagrant:
	HOSTNAME=127.0.0.1 BRANCH_NAME=$(BRANCH) REPO=/vagrant bundle exec cap vagrant deploy
