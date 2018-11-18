# coding: utf-8
module ImapFilter
  module Functionality
    include Forwardable
    include ImapFilter::DSL
    @@facc_list = nil
    
    def self._functional_accounts
      @@facc_list ||= _accounts.map { |name, acc|
        [name, FunctAccount.new( acc )]
      }.to_h
    end
    
    class FunctAccount
      extend Forwardable
      
      attr :dacc
      
      def_delegators :@dacc, :name, :userid, :pass,
                     :fqdn, :use_ssl, :use_port,
                     :auth_type, :imap, :delim, :to_s,
                     :_open_connection, :_close_connection

      def initialize acc
        @dacc = acc
      end

      def mbox_list
        @mbox_list ||= @dacc.imap.list('', '*')
                     .map { |m| [m['name'], m['attr']] }
                     .map { |mbox, attr|
          begin
            [mbox,
             [@dacc.imap.status(mbox, STATUS.values)
               .map{ |k, v| "#{ISTAT[k]}:#{v}" }
               .join(' '),
              attr]]
          rescue
            nil
          end }.compact.to_h
      end

      def member? mbox
        mbox_list.member? mbox
      end

      def ensure_mailbox mbox
        unless member? mbox
          @dacc.imap.create mbox
          @mbox_list[mbox] = [:new_mailbox, :new_mailbox]
        end
      end
    end
    
    FULL ='(UID RFC822.SIZE ENVELOPE BODY.PEEK[TEXT])'
    BODYTEXT = 'BODY[TEXT]'
    SUBJECTPEEKLIST = '(UID RFC822.SIZE BODY.PEEK[HEADER.FIELDS (SUBJECT)])'
    SUBJECTLIST = 'BODY[HEADER.FIELDS (SUBJECT)]'
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
        acc = Functionality::_functional_accounts[ a.nil? ? default_account : a.to_sym ]
        mbox = b
        [acc, mbox]
      end

      def select_email
        @acc, box = parse_and_resolve_account_mbox_string mbox
        acc.imap.select box
        @seq = acc.imap.search directives
      end

      def ensure_mailbox account, mailbox
        begin
          account.ensure_mailbox mailbox
        rescue Net::IMAP::NoResponseError => e
          puts "  *** ignored mailbox error: #{e}".red unless _options[:verbose] < 1
        end
      end

      def process_actions
        actions.each do |action|
          send *action
        end
      end

      def subject_list
        unless seq.empty?
          acc.imap.fetch(seq, SUBJECTPEEKLIST).map do |subject|
            subject.attr[SUBJECTLIST].to_s.strip.tr("\n\r", '')
          end
        else
          []
        end
      end

      def list *a, **h
        subject_list.each do |subject|
          puts subject.light_yellow
        end unless seq.empty?
      end

      def _cross_account_mvcp op, dest_acc, dest_mbox        
        ensure_mailbox dest_acc, dest_mbox
        begin
          acc.imap.fetch(seq, FULL).each do |fdat|
            unless _options[:verbose] < 2
              print "  >>".yellow
              puts " seq #{fdat.seqno} #{fdat.attr['ENVELOPE']['subject']} -> #{dest_acc.name}:#{dest_mbox}".light_blue
            end
            raw = fdat.attr['ENVELOPE'].email_header + fdat.attr[BODYTEXT]
            dest_acc.imap.append dest_mbox, raw, fdat.attr['FLAGS']
            acc.imap.noop # just to keep this account open TODO: we do not need a noop on every iteration
          end
        rescue => e
          puts "ERROR: #{e} -- perhaps you did a move or delete operation before copy?".light_red
          exit 10
        end
      end
      
      def _mvcp op, destination
        raise "Illegal operation #{op}" unless [:copy, :move].member? op
        
        dest_acc, dest_mbox = parse_and_resolve_account_mbox_string destination
        ensure_mailbox dest_acc, dest_mbox
        
        if dest_acc == acc # in-account move
          dest_acc.imap.send op, seq, dest_mbox
        else # move or copy to different account
          _cross_account_mvcp op, dest_acc, dest_mbox
        end unless seq.empty?
      end
      
      def move destination
        puts "  move from #{acc.name} to #{destination}".light_blue unless _options[:verbose] < 1
        _mvcp :move, destination unless _options[:dryrun]
      end
      
      def copy destination
        puts "  copy from #{acc.name} to #{destination}".light_blue unless _options[:verbose] < 1
        _mvcp :copy, destination unless _options[:dryrun]
      end

      def delete
        puts "  delete from #{acc.name}".light_blue unless _options[:verbose] < 1
        mark :Deleted unless _options[:dryrun]
      end
      
      def mark *flags
        puts "  mark #{flags} in #{acc.name}".light_blue unless _options[:verbose] < 1
        puts "DISCONNECTED".light_red if acc.imap.disconnected?
        acc.imap.store seq, '+FLAGS.SILENT', flags unless seq.empty? or _options[:dryrun]
      end
      
      def unmark *flags
        puts "  unmark #{flags} in #{acc.name}".light_blue unless _options[:verbose] < 1
        acc.imap.store seq, '-FLAGS.SILENT', flags unless seq.empty? or _options[:dryrun]
      end
    end
  end
end
