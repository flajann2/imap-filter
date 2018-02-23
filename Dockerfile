from ruby:2.5.0

copy secrets /secrets
copy . /opt/imap-filter

run cd /opt/imap-filter ; \
     bundle install

