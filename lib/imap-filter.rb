require 'thor'
require 'semver'
require 'pp'
require 'ap'
require 'colorize'
require 'awesome_print'
require 'net/imap'
require 'gmail_xoauth'
require 'forwardable'

module ImapFilter
end

require_relative 'imap-filter/dsl'
require_relative 'imap-filter/functionality'
require_relative 'imap-filter/imap-filter'
require_relative 'imap-filter/cli'
