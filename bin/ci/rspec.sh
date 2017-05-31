#!/bin/bash

# solr and fcrepo wrappers don't always clean up after themselves
rm -rf tmp/solr-test
rm -rf tmp/fedora/test

# ensure rbenv and ruby-build are up do date,
# since somehow the Jenkins plugin can’t do this itself
pushd ~/.rbenv
git fetch origin && git reset --hard origin/master
popd

pushd ~/.rbenv/plugins/ruby-build
git fetch origin && git reset --hard origin/master
popd

# one of our Jenkins workers is broken so we have to hold its hand
# through every little thing
export PATH="~/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

old_proxy=$http_proxy
export http_proxy=
export https_proxy=

if ! rbenv versions | grep "$RBENV_VERSION" >/dev/null 2>&1; then
  rbenv install $RBENV_VERSION
fi

gem install --no-document bundler rake
bundle install --without=production development
cp config/secrets.yml.template config/secrets.yml
make spec
