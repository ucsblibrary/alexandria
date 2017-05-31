#!/bin/bash

# one of our Jenkins workers is broken so we have to hold its hand
# through every little thing
export PATH="~/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

export http_proxy=
export https_proxy=

if ! rbenv versions | grep "$RBENV_VERSION" >/dev/null 2>&1; then
  rbenv install $RBENV_VERSION
fi

bundle install --without=production development
make cops
