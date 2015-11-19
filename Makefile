.PHONY: deploy rubocop

deploy:
	bundle exec cap vagrant deploy

rubocop:
	rubocop --format simple --config .rubocop.yml --auto-correct
