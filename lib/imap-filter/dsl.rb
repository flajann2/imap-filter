# coding: utf-8
require 'imap-filter'

module ImapFilter
  module DSL
    @@global_config = {}

    def _global
      @@global_config
    end

    def _options
      DSL::_global[:options]
    end
    
    def _accounts
      DSL::_global[:accounts] ||= {}
    end

    def _filters
      DSL::_global[:filters] ||= {}
    end

    class Dsl
      attr :name, :desc
      
      def initialize(name, desc=nil, &ignore)
        @name = name
        @desc = desc
      end
    end
    
    class Account < Dsl
      attr :name, :userid, :pass, :fqdn, :use_ssl, :use_port, :auth_type
      attr :imap, :delim
      
      def login userid, password
        @userid = userid
        @pass = password
        @use_ssl = true
        @use_port = nil
        @auth_type = 'PLAIN'
      end

      def serv fqdn
        @fqdn = fqdn
      end

      def ssl t
        @use_ssl = t
      end
      
      def port p
        @use_port = p
      end

      def auth type
        @auth_type = type.to_s.upcase
      end
      
      def initialize(name, &block)
        super
        @name = name
        instance_eval( &block )
        _accounts[name] = self        
      end

      def to_s
        "SERV #{fqdn} USER #{userid} SSL #{use_ssl} PORT #{ use_port ? use_port : '<default>'} AUTH #{auth_type} >DELIM #{delim}"
      end

      # connects and logs in
      def _open_connection
        print "\n    *** connect #{fqdn} port '#{use_port}' ssl #{use_ssl}".light_cyan unless _options[:verbose] < 2
        unless use_port.nil?
          @imap =  Net::IMAP.new(fqdn, port: use_port, ssl: use_ssl)
        else
          @imap =  Net::IMAP.new(fqdn, ssl: use_ssl)
        end

        print "\n    *** auth #{userid} pass #{pass}...".light_cyan unless _options[:verbose] < 2
        imap.authenticate(auth_type, userid, pass)
        @delim = imap.list('', '').first.delim
      end

      def _close_connection
        imap.close
      end
    end

    class Filter < Dsl
      attr :mbox, :directives, :actions
      OPS = [:or, :not, :new]
      MARKS = {
        seen: :Seen,
        read: :Seen,
        unread: :Unseen,
        unseen: :Unseen,
        deleted: :Deleted,
        flagged: :Flagged
      }
      DIRECTIVES = {
        all: 'ALL',
        new: 'NEW',
        recent: 'RECENT',
        seen: 'SEEN',
        read: 'SEEN',
        unseen: 'UNSEEN',
        unread: 'UNSEEN',
        answered: 'ANSWERED',
        unanswered: 'UNANSWERED',
        deleted: 'DELETED',
        undeleted: 'UNDELETED',
        draft: 'DRAFT',
        undraft: 'UNDRAFT',
        flagged: 'FLAGGED',
        unflagged: 'UNFLAGGED',
      }

      def list *a, **h
        @actions << [:list, a, h]
      end
      
      def move to_mbox
        @actions << [:move, to_mbox]
      end
      alias mv move

      def copy to_mbox
        @actions << [:copy, to_mbox]
      end
      alias cp copy
      
      def delete
        @actions << [:delete]
      end

      def mark *flags, custom: false
        flags.each do |f|
          raise "Illegal flag #{f}" unless MARKS.member? f
        end unless custom
        @actions << [:mark] + flags.map{ |f| MARKS[f] || f }
      end
      alias store mark

      def unmark *flags,  custom: false
        flags.each do |f|
          raise "Illegal flag #{f}" unless MARKS.member? f
        end unless custom
        @actions << [:unmark] + flags.map{ |f| MARKS[f] || f }
      end
      alias unstore unmark

      def search &block        
        def before d
          directives << 'BEFORE' << d
        end

        def body s
          directives << 'BODY'<< s
        end

        def cc s
          directives << 'CC' << s
        end

        def bcc s
          directives << 'BCC' << s
        end

        def from s
          directives << 'FROM' << s
        end

        def op *a          
          a.each { |x|
            raise "illegal operator #{x}" unless OPS.member? x
            directives << x.to_s.upcase
          }
        end          
        
        def on d
          directives << 'ON' << d
        end

        def since d
          directives << 'SINCE' << d
        end
        
        def senton d
          directives << 'SENTON' << d
        end
        
        def sentsince d
          directives << 'SENTSINCE' << d
        end
        
        def sentbefore d
          directives << 'SENTBEFORE' << d
        end
        
        def smaller n 
          directives << 'SMALLER' << n
        end

        def subject s
          directives << 'SUBJECT' << s
        end
        
        def text s
          directives << 'TEXT' << s
        end

        def to s
          directives << 'TO' << s
        end

        def all
          directives << 'ALL'
        end
        
        def answered
          directives << 'ANSWERED'
        end
        
        def unanswered
          directives << 'UNANSWERED'
        end
        
        def deleted
          directives << 'DELETED'
        end
        
        def undeleted
          directives << 'UNDELETED'
        end
        
        def draft
          directives << 'DRAFT'
        end
        
        def undraft
          directives << 'UNDRAFT'
        end
        
        def flagged
          directives << 'FLAGGED'
        end
        
        def unflagged
          directives << 'UNFLAGGED'
        end
        
        def seen
          directives << 'SEEN'
        end
        alias red seen
        
        def unseen
          directives << 'UNSEEN'
        end
        alias unread unseen
        
        def keyword key
          directives << 'KEYWORD' << key
        end      
        
        def unkeyword key
          directives << 'UNKEYWORD' << key
        end      
        
        instance_eval &block        
      end
      
      # note that directives can be either a hash or a single symbol
      def initialize(name, mbox, directives=[], &block)
        super(name)
        @mbox = mbox
        @directives = if directives.is_a?(Hash)
                        directives.map{|k,v| [k.to_s.upcase, v]}.flatten
                      elsif directives.is_a?(Symbol)
                        DIRECTIVES[directives]
                      else
                        directives
                      end
        @actions = []
        instance_eval &block 
        _filters[name] = self
      end

      def to_s
        "MBOX #{mbox} DIRECTIVES #{directives}"
      end
    end
    
    def account name, &block
      Account.new name, &block
    end

    def filter name, mbox, singledir=nil, **directives, &block
      Filter.new name, mbox, (singledir || directives), &block
    end
    
    def activate filters
      Functionality.run_filters filters
    end
  end
end
