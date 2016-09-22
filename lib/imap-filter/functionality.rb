module ImapFilter
  module Functionality
    include Forwardable
    
    class FunctFilter
      extend Fowardable
      
      attr :dfilt
      def_delegators :@dfilt, :mbox, :directives, :actions
                     
      def initialize filt
        @dfilt = filt
      end

      def select_email
      end
    end

    
  end
end
