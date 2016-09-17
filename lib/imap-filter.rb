require 'thor'
require 'semver'
require 'pp'
requrie 'ap'
require 'colorize'
require 'awesome_print'
require 'net/imap'

module ImapFilter
end

require_relative 'imap-filter/cli'
require_relative 'imap-filter/dsl'
require_relative 'imap-filter/imap-filter'
