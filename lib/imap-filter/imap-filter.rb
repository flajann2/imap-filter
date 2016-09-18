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
    
    def self.run_filters filters
      unless _options[:verbose] < 1
        show_imap_plan
      end
      
    end
  end
end
