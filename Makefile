.PHONY: prod rubocop vagrant

vagrant:
	SERVER=127.0.0.1 REPO=/vagrant bundle exec cap vagrant deploy

prod:
	REPO=ssh://git@stash.library.ucsb.edu:7999/dr/adrl-v2.git bundle exec cap production deploy

rubocop:
	rubocop --format simple --config .rubocop.yml --auto-correct
