class Net::IMAP::Envelope
  CRLF = "\r\n"
  HEDCNS = [
    ['Date:', ->(){ date } ],
    ['Subject:', ->(){ subject } ],
    ['Date:', ->(){ date } ],
    ['Message-ID:', ->(){ message_id }],
    ['Sender:', ->(){
       sender.map{ |f|
         "#{f.name} <#{f.mailbox}@#{f.host}>"
       }.join ',' } unless.sender.nil? ],
    ['From:', ->(){
       from.map{ |f|
         "#{f.name} <#{f.mailbox}@#{f.host}>"
       }.join ',' } unless.from.nil? ],
    ['To:', ->(){
       to.map{ |f|
         "#{f.name} <#{f.mailbox}@#{f.host}>"
       }.join ',' } unless.to.nil? ],
    ['Cc:', ->(){
       cc.map{ |f|
         "#{f.name} <#{f.mailbox}@#{f.host}>"
       }.join ',' } unless.cc.nil? ],
    ['Bcc:', ->(){
       bcc.map{ |f|
         "#{f.name} <#{f.mailbox}@#{f.host}>"
       }.join ',' } unless.bcc.nil? ],

  ].to_h
  def email_header
  end
end


