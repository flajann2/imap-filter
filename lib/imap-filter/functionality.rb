module ImapFilter
  module Functionality
    include Forwardable
    include ImapFilter::DSL

    SEARCH_CRITERIA = {
      all: nil,
      new: nil,
      seen: nil
    }
    
    class FunctFilter
      extend Forwardable
      
      attr :dfilt, :seq, :acc
      
      def_delegators :@dfilt, :mbox, :directives, :actions
                     
      def initialize filt
        @dfilt = filt
        @seq = nil
      end

      # These strings come from the DSL in the form of
      # "acct:mbox_path". Reslove and return the actual
      # account object and mbox path as [account_ob, mbox]
      def parse_and_resolve_account_mbox_string ambox, default_account = nil
        a, b = ambox.split ':'
        a, b = [nil, a] if b.nil?
        a = nil if a == ''
        acc = a.nil? ? default_account : _accounts[a.to_sym]
        mbox = b
        [acc, mbox]
      end

      # Take directives and transform them into more general
      # search criteria
      def search_criteria
        require 'pry'; binding.pry #DEBUGGING
        directives
      end
      
      def select_email
        @acc, box = parse_and_resolve_account_mbox_string mbox
        acc.imap.select box
        @seq = acc.imap.search search_criteria
      end

      def ensure_mailbox mailbox
        begin
          acc.imap.create mailbox
        rescue Net::IMAP::NoResponseError => e
          # we ignore this because it -- probably -- means the mailbox already exists.
        end
      end

      def process_actions
        actions.each do |action|
          send *action
        end
      end

      def subject_list
        subj = 'BODY[HEADER.FIELDS (SUBJECT)]'
        unless seq.empty?
          acc.imap.fetch(seq, subj).map do |subject|
            subject.attr[subj].to_s.strip.tr("\n\r", '')
          end
        else
          []
        end
      end

      def list *a, **h
        subject_list.each do |subject|
          puts subject.attr[subj].to_s.strip.tr("\n\r", '').light_yellow
        end unless seq.empty?
      end

      def _mvcp op, destination
        raise "Illegal operation #{op}" unless [:copy, :move].member? op
        dest_acc, dest_mbox = parse_and_resolve_account_mbox_string destination
        if dest_acc == acc # in-account move
          ensure_mailbox dest_mbox
          dest_acc.imap.send op, seq, dest_mbox
        else # move or copy to different account
          raise "Not Implemented Yet"
        end unless seq.empty?
      end
      
      def move destination
        puts "  move from #{acc.name} to #{destination}".light_blue unless _options[:verbose] < 1
        _mvcp :move, destination unless _options[:dryrun]
      end
      
      def copy destination
        puts "  copy from #{acc.name} to #{destination}"-light_blue unless _options[:verbose] < 1
        _mvcp :copy, destination unless _options[:dryrun]
      end

      def delete
        puts "  delete from #{acc.name}"-light_blue unless _options[:verbose] < 1
        mark :Deleted unless _options[:dryrun]
      end
      
      def mark *flags
        puts "  mark in #{acc.name}"-light_blue unless _options[:verbose] < 1
        acc.imap.store seq, '+FLAGS.SILENT', flags unless _options[:dryrun]
      end
      
      def unmark *flags
        puts "  unmark in #{acc.name}"-light_blue unless _options[:verbose] < 1
        acc.imap.store seq, '-FLAGS.SILENT', flags unless _options[:dryrun]
      end
    end
  end
end
