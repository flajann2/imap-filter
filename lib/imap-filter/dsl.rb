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
      attr :name,
           :userid,
           :pass,
           :fqdn,
           :use_ssl,
           :use_port,
           :auth_type,
           :login_type,
           :consumer_key,
           :consumer_secret

      attr :imap, :delim

      LOGIN_TYPES = {
        oauth1: 'XOUATH',
        oauth2: 'XOAUTH2',
        plain: 'PLAIN' }

      def login userid, password = nil,
                type: :plain,
                key: nil,
                secret: nil
        @userid = userid
        @pass = password
        @use_ssl = true
        @use_port = nil
        @login_type = type
        @auth_type = LOGIN_TYPES[type]
        @consumer_key = key
        @consumer_secret = secret
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
        @imap.account = self

        print "\n    *** auth #{userid} type #{auth_type} pass #{pass} key #{consumer_key}...".light_cyan unless _options[:verbose] < 2
        print "\n    *** capability #{imap.capability().join(',')}".light_cyan unless _options[:verbose] < 2
        _authenticate
        @delim = imap.list('', '').first.delim
      end

      def _authenticate
        case login_type
        when :plain, :oauth2
          #Net::IMAP.debug = true
          require 'pry'; binding.pry if userid == ENV['GOOGLE_REPLICONICS_EMAIL'] #DEBUGGING
          imap.authenticate(auth_type, userid, pass)

        when :oauth1 # userid is consumer_key, pass is consumer_secret
          imap.authenticate(auth_type, userid,
                            two_legged: true,
                            consumer_key: consumer_key,
                            consumer_secret: consumer_secret)
        end
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

      def massage directives
        if directives.is_a?(Hash)
          directives.map{ |k, v|
            unless v.is_a? Array
              [k.to_s.upcase, v]
            else
              ['OR',
               v.map{ |va|
                 [k.to_s.upcase, va]
               }].flatten
            end
          }.flatten
        elsif directives.is_a?(Symbol)
          DIRECTIVES[directives]
        else
          directives
        end
      end

      # note that directives can be either a hash or a single symbol
      def initialize(name, mbox, directives=[], &block)
        super(name)
        @mbox = mbox
        @directives = massage directives
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
