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
#
# UPDATE:  I see this entry in the release notes for curation_concerns 1.7.0, so maybe we can delete this file the next time we upgrade CC:
# 2016-10-18: Change when AF::Noid is required so it doesn't break in production mode. [Michael J. Giarlo]

# class MinterState; end
