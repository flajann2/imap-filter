require 'imap-filter'

include ImapFilter::DSL

module ImapFilter
  module Functionality
    def self.show_imap_plan
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

    def self.test_imap_accounts
      puts '====== Testing Accounts'.light_yellow
      _accounts.each do |name, account|
        print "  Testing #{name}...".light_white
        begin
          account._open_connection
          #account._close_connection
          puts "SUCCESS".light_green
        rescue => e
          puts "FAILED: #{e}".light_red          
        end
      end
    end

    def self.execute_filters
    end
    
    def self.run_filters filters
      show_imap_plan unless _options[:verbose] < 1
      if _options[:test]
        test_imap_accounts
      else
        execute_filters
      end
    end
  end
end
