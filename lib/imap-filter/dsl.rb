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
      attr :userid, :pass, :fqdn, :use_ssl, :use_port, :auth_type
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

      def mark state
        @actions << [:mark, state]
      end

      def search &block        
        def before d
          directives << 'BEFORE' << d
        end

        def body s
          directives << 'BODY'<< s
        end

        def cc s
          directives <<  'CC'<< s
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

        def subject s
          directives << 'SUBJECT' << s
        end

        def to s
          directives << 'TO' << s
        end
        
        instance_eval &block        
      end
      
      # note that directives can be either a hash or a single symbol
      def initialize(name, mbox, directives=[], &block)
        super(name)
        @mbox = mbox
        @directives = directives.is_a?(Hash) ? directives.map{|k,v| [k.to_s.upcase, v]}.flatten : directives
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
