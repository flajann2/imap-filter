require 'imap-filter'

include ImapFilter::DSL

module ImapFilter
  module Functionality
    def self.run_filters filters
      unless _options[:verbose] < 1
        puts '====== Accounts'.light_yellow
        _accounts.each do |name, account|
          print " #{name}: ".light_green
          print account.to_s.light_blue
          puts
        end
        puts '====== Filters'.light_yellow
        _filters.each do |name, filter|
          print " #{name}: ".light_green
          print filter.to_s.light_blue
          puts          
        end
      end
    end
  end
end
