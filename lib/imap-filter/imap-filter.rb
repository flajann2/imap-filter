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
    
    def self.login_imap_accounts test: false
      puts "====== #{test ? 'Test' : 'Login'} Accounts".light_yellow
      _accounts.each do |name, account|
        print "  Testing #{name}...".light_white
        begin
          account._open_connection
          puts "SUCCESS".light_green
        rescue => e
          puts "FAILED: #{e}".light_red
          exit unless test
        end
      end
    end

    def self.execute_filters
      login_imap_accounts
    end
    
    def self.run_filters filters
      show_imap_plan unless _options[:verbose] < 1
      if _options[:test]
        login_imap_accounts test: true
      else
        execute_filters
      end
    end
  end
end
