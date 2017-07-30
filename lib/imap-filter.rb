require 'thor'
require 'semver'
require 'pp'
require 'ap'
require 'colorize'
require 'awesome_print'
require 'net/imap'
require 'forwardable'
require 'aspector'
require 'gmail_xoauth'

module ImapFilter
end

require_relative 'imap-filter/monkeypatches'
require_relative 'imap-filter/dsl'
require_relative 'imap-filter/functionality'
require_relative 'imap-filter/imap-filter'
require_relative 'imap-filter/cli'
