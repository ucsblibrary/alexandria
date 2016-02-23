.PHONY: prod rubocop spec vagrant

prod:
	bundle exec cap production deploy

rubocop:
	rubocop --format simple --config .rubocop.yml --auto-correct

spec:
	CI=1 RAILS_ENV=test bundle exec rake ci --trace

vagrant:
	SERVER=127.0.0.1 REPO=/vagrant bundle exec cap vagrant deploy
