# coding: utf-8
require 'imap-filter'

include ImapFilter::DSL

module ImapFilter
  module Functionality
    STATUS = {messages: 'MESSAGES', recent: 'RECENT', unseen: 'UNSEEN'}
    ISTAT = STATUS.map{ |k, v| [v, k] }.to_h
    
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

    # List all mboxes of given account and their statuses
    def self.list_mboxes account
      account.imap.list('', '*')
        .map { |m| [m['name'], m['attr']] }
        .map { |mbox, attr|
        begin
          [mbox,
           account.imap.status(mbox, STATUS.values)
             .map{ |k, v| "#{ISTAT[k]}:#{v}" }
             .join(' '),
           attr]
        rescue
          nil
        end }
        .compact
    end
    
    def self.login_imap_accounts test: false
      puts "====== #{test ? 'Test' : 'Login'} Accounts".light_yellow
      _functional_accounts.each do |name, account|
        print "  #{name}...".light_white
        begin
          account._open_connection
          account.mbox_list = list_mboxes(account)
          puts "SUCCESS, delim #{account.delim}".light_green          
          
          account.mbox_list.each do |mbox, stat, attr|
            print "  #{mbox}".light_blue
            print " #{stat}".light_red
            puts " #{attr}".light_cyan
          end unless _options[:verbose] < 2
        rescue => e
          puts "FAILED: #{e}".light_red
          exit unless test
        end
      end
    end

    def self.list_of_filters_to_run
      unless _options[:filters].nil?
        _options[:filters].map{ |f| f.to_sym }
      else
        _filters.keys
      end
    end

    # do the selection based on directives
    # then perform the actions on the set selected.
    # optimize for copy/moves that are to the same account.
    def self.run_filter filt
      f = FunctFilter.new _filters[filt]
      f.select_email
      
      unless _options[:verbose] < 1
        puts "====== Email to be processed by #{filt}".light_yellow
        f.subject_list.each do |subject|
          print '  ##'.yellow
          puts subject.light_blue
        end
      end
      
      f.process_actions 
      f.acc.imap.expunge unless _options[:dryrun]
    end
    
    def self.execute_filters
      #login_imap_accounts
      list_of_filters_to_run.each do |f|
        print "Running filter: ".light_white
        puts "#{f}".light_yellow
        run_filter f
      end
    end
    
    def self.run_filters filters
      show_imap_plan unless _options[:verbose] < 1
      if _options[:test]
        login_imap_accounts test: true
      else
        login_imap_accounts
        execute_filters
      end
    end
  end
end
