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
      attr :userid, :pass, :fqdn, :use_ssl, :use_port
      
      def login userid, password
        @userid = userid
        @pass = pass
        @use_ssl = true
        @use_port = nil
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
      
      def initialize(name, &block)
        super
        instance_eval( &block )
        _accounts[name] = self        
      end

      def to_s
        "USER #{userid} SSL #{use_ssl} PORT #{ use_port ? use_port : '<default>'}"
      end
    end

    class Filter < Dsl
      attr :mbox, :directives, :actions

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
      
      # note that directives can be either a hash or a single symbol
      def initialize(name, mbox, directives, &block)
        super(name)
        @mbox = mbox
        @directives = directives
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
