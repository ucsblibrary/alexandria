.PHONY: vagrant rubocop

vagrant:
	bundle exec cap vagrant deploy

prod:
	bundle exec cap production deploy

rubocop:
	rubocop --format simple --config .rubocop.yml --auto-correct
