FROM ruby:2.7.1-alpine AS build-env
ARG RAILS_ROOT=/var/www/deploy/current
ARG BUILD_PACKAGES="build-base bash git openssh gcc"
ARG DEV_PACKAGES="python3-dev musl-dev mariadb-dev"
ARG RUBY_PACKAGES="tzdata"
ENV RAILS_ENV=production
ENV NODE_ENV=production
ENV BUNDLE_APP_CONFIG="$RAILS_ROOT/.bundle"
WORKDIR $RAILS_ROOT
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories \
    && gem sources -a https://mirrors.aliyun.com/rubygems/  --remove https://rubygems.org/ \
    && apk add --update --no-cache $BUILD_PACKAGES $DEV_PACKAGES $RUBY_PACKAGES
COPY . .
RUN bundle config set without "development test" \
    && bundle install
FROM ruby:2.7.1-alpine
ARG RAILS_ROOT=/var/www/deploy/current
ARG PACKAGES="bash tzdata mariadb-dev curl-dev"
ENV BUNDLE_APP_CONFIG="$RAILS_ROOT/.bundle"
WORKDIR $RAILS_ROOT
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.ustc.edu.cn/g' /etc/apk/repositories \
    && apk add --update --no-cache $PACKAGES \ 
    && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime 
COPY --from=build-env $RAILS_ROOT $RAILS_ROOT
COPY --from=build-env /usr/local/bundle/ /usr/local/bundle/
EXPOSE 3000
RUN echo 'cd /var/www/deploy/current'                	       >> run.sh   && \
    echo 'rm -f /var/www/deploy/current/tmp/pids/server.pid'   >> run.sh   && \
    echo '#RAILS_ENV=production rails db:create'               >> run.sh   && \
    echo 'RAILS_ENV=production rails db:migrate'               >> run.sh   && \
    echo '#whenever -c && whenever -i && whenever -w'          >> run.sh   && \
    echo '#crond '                                             >> run.sh   && \
    echo 'echo $(date +%Y%m%d_%H%M%S) >> /tmp/start-run.txt'   >> run.sh   && \  
    echo 'cd /var/www/deploy/current && RAILS_ENV=production rails s -d -b 0.0.0.0 -p 3000' >> run.sh
#CMD ["rails", "server", "-b", "0.0.0.0"]
CMD bash run.sh;while true;do sleep 10;done
