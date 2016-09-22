module ImapFilter
  module Functionality
    include Forwardable
    include ImapFilter::DSL

    class FunctFilter
      extend Forwardable
      
      attr :dfilt
      def_delegators :@dfilt, :mbox, :directives, :actions
                     
      def initialize filt
        @dfilt = filt
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
        acc, box = parse_and_resolve_account_mbox_string mbox
        acc.imap.select box
        
        require 'pry'; binding.pry #DEBUGGING
      end
    end

    
  end
end
