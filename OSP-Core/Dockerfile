FROM alpine:latest
MAINTAINER David Lockwood

ARG OSP_VERSION=0.8.16
ARG OSP_GIT_BRANCH=nightly

ARG NGINX_VERSION=1.17.3
ARG NGINX_RTMP_VERSION=1.2.1

ARG DEFAULT_DB_URL=mysql+pymysql://osp:password@db/osp?charset=utf8mb4
ARG DEFAULT_REDIS_HOST=redis
ARG DEFAULT_REDIS_PORT=6379
ARG DEFAULT_REDIS_PASSWORD=
ARG DEFAULT_FLASK_SECRET=CHANGEME
ARG DEFAULT_FLASK_SALT=CHANGEME
ARG DEFAULT_OSP_ALLOWREGISTRATION=True
ARG DEFAULT_OSP_REQUIREVERIFICATION=True
ARG DEFAULT_OSP_EJABBERDPASS=CHANGEME
ARG DEFAULT_OSP_EJABBERDSERVER=127.0.0.1
ARG DEFAULT_OSP_EJABBERDHTTPBINDFQDN="streams.example.com"
ARG DEFAULT_TZ="ETC/UTC"
ARG DEFAULT_OSP_CORE_UI_DEBUG=False
ARG DEFAULT_OSP_CORE_LOG_LEVEL=error

ENV DB_URL=${DEFAULT_DB_URL}
ENV REDIS_HOST=${DEFAULT_REDIS_HOST}
ENV REDIS_PORT=${DEFAULT_REDIS_PORT}
ENV REDIS_PASSWORD=${DEFAULT_REDIS_PASSWORD}
ENV FLASK_SECRET=${DEFAULT_FLASK_SECRET}
ENV FLASK_SALT=${DEFAULT_FLASK_SALT}
ENV OSP_ALLOWREGISTRATION=${DEFAULT_OSP_ALLOWREGISTRATION}
ENV OSP_REQUIREVERIFICATION=${DEFAULT_OSP_REQUIREVERIFICATION}
ENV EJABBERDADMIN=admin
ENV EJABBERDPASS=${DEFAULT_OSP_EJABBERDPASS}
ENV EJABBERDHOST=localhost
ENV EJABBERDSERVER=${DEFAULT_OSP_EJABBERDSERVER}
ENV EJABBERDHTTPBINDFQDN=${DEFAULT_OSP_EJABBERDHTTPBINDFQDN}
ENV OSP_CORE_UI_DEBUG=${DEFAULT_OSP_CORE_UI_DEBUG}
ENV OSP_CORE_LOG_LEVEL=${DEFAULT_OSP_CORE_LOG_LEVEL}

EXPOSE 80/tcp
EXPOSE 443/tcp

# Get initial dependancies
RUN apk update
RUN apk add alpine-sdk \
  pcre-dev \
  libressl-dev \
  openssl-dev \
  libffi-dev \
  wget \
  git \
  linux-headers \
  zlib-dev \
  postgresql-dev \
  gcc \
  libgcc \
  musl-dev \
  jpeg-dev \
  zlib-dev

RUN apk add --no-cache tzdata

ENV TZ=$DEFAULT_TZ

RUN apk add --no-cache bash

# Download OSP from Repo
#RUN cd /tmp && \
#  wget "https://gitlab.com/Deamos/flask-nginx-rtmp-manager/-/archive/${OSP_VERSION}/flask-nginx-rtmp-manager-${OSP_VERSION}.tar.gz" && \
#  tar zxf flask-nginx-rtmp-manager-${OSP_VERSION}.tar.gz && \
#  rm flask-nginx-rtmp-manager-${OSP_VERSION}.tar.gz

# Clone Branch Instead
RUN cd /tmp && git clone https://gitlab.com/Deamos/flask-nginx-rtmp-manager.git && cd flask-nginx-rtmp-manager && git checkout ${OSP_GIT_BRANCH}

# Make OSP Install Directory
RUN mv /tmp/flask-nginx-rtmp-manager /opt/osp/

# Transfer OSP Docker Files
COPY docker-files.d/entrypoint.sh /opt/osp/setup/
COPY docker-files.d/supervisord.conf /opt/osp/setup
COPY docker-files.d/wait-for-it.sh /opt/osp/setup

# Create the www-data user
RUN set -x ; \
  addgroup -g 82 -S www-data ; \
  adduser -u 82 -D -S -G www-data www-data && exit 0 ; exit 1

# Set the OSP directory to www-data
RUN chown -R www-data:www-data /opt/osp

# Download NGINX
RUN cd /tmp && \
  wget https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
  tar zxf nginx-${NGINX_VERSION}.tar.gz && \
  rm nginx-${NGINX_VERSION}.tar.gz

# Download the NGINX-RTMP Module
RUN cd /tmp && \
  wget https://github.com/arut/nginx-rtmp-module/archive/v${NGINX_RTMP_VERSION}.tar.gz && \
  tar zxf v${NGINX_RTMP_VERSION}.tar.gz && rm v${NGINX_RTMP_VERSION}.tar.gz

RUN cd /tmp && \
  wget "https://bitbucket.org/nginx-goodies/nginx-sticky-module-ng/get/master.tar.gz" && \
  tar xxf master.tar.gz

# Compile NGINX with the NGINX-RTMP Module
RUN cd /tmp/nginx-${NGINX_VERSION} && \
  ./configure \
  --with-http_ssl_module \
  --with-http_v2_module \
  --with-http_auth_request_module \
  --with-cc-opt="-Wimplicit-fallthrough=0" \
  --add-module=../nginx-rtmp-module-${NGINX_RTMP_VERSION} \
  --add-module=../nginx-goodies-nginx-sticky-module-ng-08a395c66e42 && \
  cd /tmp/nginx-${NGINX_VERSION} && make && make install

RUN rm -rf /tmp/nginx-${NGINX_VERSION}

# Configure NGINX
RUN mkdir /usr/local/nginx/conf/locations
RUN mkdir /usr/local/nginx/conf/upstream
RUN mkdir /usr/local/nginx/conf/custom
RUN cp /opt/osp/installs/nginx-core/nginx.conf /usr/local/nginx/conf/
RUN cp /opt/osp/installs/nginx-core/mime.types /usr/local/nginx/conf/
RUN cp /opt/osp/setup/nginx/locations/* /usr/local/nginx/conf/locations
RUN cp /opt/osp/setup/nginx/upstream/* /usr/local/nginx/conf/upstream
RUN cp /opt/osp/installs/nginx-core/osp-custom-*.conf /usr/local/nginx/conf/custom


# Install Python, Gunicorn, and uWSGI
RUN apk add python3 \
  py3-pip \
  py3-setuptools \
  python3-dev \
  py3-gunicorn \
  uwsgi-python3

# Upgrade PIP
RUN pip3 install cryptography==3.3.2
RUN pip3 install --upgrade pip

# Install OSP Dependancies
RUN pip3 install -r /opt/osp/setup/requirements.txt

# Setup FFMPEG for recordings and Thumbnails
RUN apk add ffmpeg

# Add Dialog (used in osp-config.sh)
RUN apk add dialog

# Setup Wait-For-It Script
RUN chmod +x /opt/osp/setup/wait-for-it.sh

# Install Supervisor
RUN apk add supervisor
RUN mkdir -p /var/log/supervisor

EXPOSE 80

VOLUME ["/var/www", "/usr/local/nginx/conf", "/opt/osp/conf"]

RUN chmod +x /opt/osp/osp-config.sh
RUN chmod +x /opt/osp/setup/entrypoint.sh
ENTRYPOINT ["/bin/sh","-c", "/opt/osp/setup/entrypoint.sh"]
