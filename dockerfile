FROM ruby:2.3.1

RUN gem install redis && \
	wget http://download.redis.io/releases/redis-3.2.5.tar.gz && \
	tar xzf redis-3.2.5.tar.gz

WORKDIR /redis-3.2.5/src

ADD /config/ruby/redis-trib.rb /redis-3.2.5/src/redis-trib.rb

RUN chmod +x /redis-3.2.5/src/redis-trib.rb

ENTRYPOINT ["./redis-trib.rb"]