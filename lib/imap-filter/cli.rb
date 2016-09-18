# coding: utf-8
require 'imap-filter'

include ImapFilter::DSL

module ImapFilter
  module Cli
    class Main < Thor
      class_option :verbose, type: :numeric, banner: '[1|2|3|4]', aliases: '-v', default: 0
      @@default_script = ENV['IMAPF_IMAP_FILE'] || 'default.imap' 
      
      desc 'filter [script]', "Run the powerplay script. Default #{@@default_script}"
      def filter(script = @@default_script)
        DSL::_global[:options] = options
        puts "script %s " % [script] if DSL::_options[:verbose] >= 1
        load script, true
        
      end
    end
  end
end
