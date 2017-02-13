# frozen_string_literal: true
# This is a work-around to allow us to run Alexandria in
# production mode.  If this file doesn't exist, we get this
# error when running rails server or rails console in
# production mode:
# activesupport-4.2.6/lib/active_support/dependencies.rb:274:in `require': No such file to load -- minter_state (LoadError)
#
# TODO:  Delete this file once this issue is fixed.
#
# See this:
# https://github.com/projecthydra-labs/active_fedora-noid/issues/29
#
# See also:
# https://github.com/projecthydra/curation_concerns/issues/1045

# class MinterState; end
