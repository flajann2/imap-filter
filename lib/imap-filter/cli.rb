require 'imap-filter'

module ImapFilter
  module Cli
    class Main < Thor
      class_option :verbose, type: :numeric, banner: '[1|2|3|4]', aliases: '-v', default: 0
      def run(script = ENV['IMAPF_IMAP_FILE'] || 'default.imap')
        
      end
    end
  end
end
