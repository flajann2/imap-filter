module ImapFilter
  module Functionality
    include Forwardable
    include ImapFilter::DSL

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
      
      def select_email
        @acc, box = parse_and_resolve_account_mbox_string mbox
        acc.imap.select box
        @seq = acc.imap.search directives
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

      def list *a, **h
        subj = 'BODY[HEADER.FIELDS (SUBJECT)]'
        acc.imap.fetch(seq, subj).each do |subject|
          puts subject.attr[subj].to_s.strip.tr("\n\r", '').light_yellow
        end unless seq.empty?
      end

      def move destination
        dest_acc, dest_mbox = parse_and_resolve_account_mbox_string destination
        if dest_acc == acc # in-account move
          ensure_mailbox dest_mbox
          dest_acc.imap.move seq, dest_mbox
        else # move to different account
          raise "Not Implemented Yet"
        end unless seq.empty?
      end
      
      def copy destination
        dest_acc, dest_mbox = parse_and_resolve_account_mbox_string destination
        if dest_acc == acc # in-account move
          ensure_mailbox dest_mbox
          dest_acc.imap.copy seq, dest_mbox
        else # copy to different account
          raise "Not Implemented Yet"
        end unless seq.empty?
      end
      
    end
    
  end
end
