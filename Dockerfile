FROM ruby:2.5-alpine

WORKDIR /app
COPY . .
COPY root /var/spool/cron/crontabs/root

RUN apk update && \
    apk add mysql \
            mysql-client \
            mysql-dev \
            curl \
            curl-dev \
            nodejs \
            libstdc++ \
            libxml2-dev \
            libxslt-dev \
            linux-headers \
            pcre \
            ruby-dev \
            ruby-json \
            tzdata \
            yaml \
            yaml-dev \
            zlib-dev \
            build-base && \
    cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && \
    apk del tzdata && \
    bundle

CMD ["crond", "-f", "-d", "1"]
