class Net::IMAP::Envelope
  CRLF = "\r\n"
  HEDCNS = [
    ['Date:', ->(s){ s.date } ],
    ['Subject:', ->(s){ s.subject } ],
    ['Date:', ->(s){ s.date } ],
    ['Message-ID:', ->(s){ s.message_id }],
    ['Sender:', ->(s){
       s.sender.map{ |f|
         "#{f.name} <#{f.mailbox}@#{f.host}>"
       }.join ',' unless s.sender.nil? } ],
    ['From:', ->(s){
       s.from.map{ |f|
         "#{f.name} <#{f.mailbox}@#{f.host}>"
       }.join ',' unless s.from.nil? } ],
    ['To:', ->(s){
       s.to.map{ |f|
         "#{f.name} <#{f.mailbox}@#{f.host}>"
       }.join ',' unless s.to.nil? } ],
    ['Cc:', ->(s){
       s.cc.map{ |f|
         "#{f.name} <#{f.mailbox}@#{f.host}>"
       }.join ',' unless s.cc.nil? } ],
    ['Bcc:', ->(s){
       s.bcc.map{ |f|
         "#{f.name} <#{f.mailbox}@#{f.host}>"
       }.join ',' unless s.bcc.nil? } ],
    ['In-Reply-To:', ->(s){ s.in_reply_to }],
  ].to_h
  
  def email_header
    HEDCNS.map{ |field, fun| "#{field} #{fun.(self)}" }
      .join CRLF
  end
end

class Net::IMAP
  def account= acc
    @account = acc
  end
  def account
    @account
  end
end

class IMAPHooks < Aspector::Base
  default private_methods: true
end

