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
      attr :userid, :pass, :fqdn
      
      def login userid, password
        @userid = userid
        @pass = pass
      end

      def serv fqdn
        @fqdn = fqdn
      end

      def initialize(name, &block)
        super
        instance_eval( &block )
        _accounts[name] = self        
      end
    end

    class Filter < Dsl
      
      def initialize(name, &block)
        super
        instance_eval( &block )
        _filters[name] = self
      end
    end
    
    def account name, &block
    end

    def filter name, mbox, singledir=nil, **directives, &block
    end
    
    def activate filters
    end
  end
end
