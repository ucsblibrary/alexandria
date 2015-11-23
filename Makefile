.PHONY: vagrant rubocop

vagrant:
	echo development > env
	bundle exec cap vagrant deploy

prod:
	echo production > env
	bundle exec cap production deploy

rubocop:
	rubocop --format simple --config .rubocop.yml --auto-correct
