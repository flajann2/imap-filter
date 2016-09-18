require 'imap-filter'

include ImapFilter::DSL

module ImapFilter
  module Functionality
    def self.run_filters filters
      ap _accounts
      ap _filters
    end
  end
end
