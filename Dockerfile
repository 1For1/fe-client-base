FROM alpine:latest

#
# Openresty docker image
#
# This docker contains openresty (nginx) compiled from source with useful optional modules installed.
#
# http://github.com/tenstartups/openresty-docker
#

FROM ubuntu:xenial

MAINTAINER JobSonic "ops@1jobsonic.com"

ENV OPENRESTY_VERSION=1.9.15.1 \
  DEBIAN_FRONTEND=noninteractive \
  TERM=xterm-color \
  npm_lifecycle_event=build \
  NODE_HOST=localhost \
  NODE_PORT=3000 \
  DEBCONF_NONINTERACTIVE_SEEN=true

# Install packages.
RUN apt-get update && apt-get -y install \
  build-essential \
  curl \
  libreadline-dev \
  libncurses5-dev \
  libpcre3-dev \
  libssl-dev \
  nano \
  perl \
  wget \
  git \
  software-properties-common wget && \
  add-apt-repository -y ppa:mozillateam/firefox-next
#  add-apt-repository -y ppa:fkrull/deadsnakes-python2.7 \

RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
RUN echo "deb http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list
RUN apt-get update -y
RUN apt-get install -y -q \
  firefox \
  google-chrome-beta \
  openjdk-8-jre-headless \
  x11vnc \
  xvfb \
  xfonts-100dpi \
  xfonts-75dpi \
  xfonts-scalable \
  xfonts-cyrillic \
  python


# Compile openresty from source.
RUN \
  addgroup --system nginx && \
  adduser --disabled-login --system --home /var/cache/nginx --shell /sbin/nologin --ingroup nginx nginx && \
  wget http://openresty.org/download/ngx_openresty-$OPENRESTY_VERSION.tar.gz && \
  tar -xzvf ngx_openresty-*.tar.gz && \
  rm -f ngx_openresty-*.tar.gz && \
  cd ngx_openresty-* && \
  ./configure --with-pcre-jit --with-ipv6 --with-lua51 --with-luajit && \
  make && \
  make install && \
  make clean && \
  cd .. && \
  rm -rf ngx_openresty-*&& \
  ln -s /usr/local/openresty/nginx/sbin/nginx /usr/local/bin/nginx && \
  rm -f /usr/sbin/nginx && \
  ln -s /usr/local/openresty/nginx/sbin/nginx /usr/sbin/nginx && \
  ldconfig && \
  useradd -d /home/seleuser -m seleuser && \
  mkdir -p /home/seleuser/chrome && \
  chown -R seleuser /home/seleuser && \
  chgrp -R seleuser /home/seleuser


RUN mkdir /app \
    && mkdir -p /etc/nginx/conf.d /var/log/nginx \
    && curl -sL https://deb.nodesource.com/setup_6.x | bash -

RUN apt-get install -y nodejs vim \
    && npm install -g npm \
    && npm install -g webpack \
    && npm install -g typings \
    && npm rebuild node-sass

# Set the working directory.
WORKDIR /app

# Add files to the container.
ADD . /app
ADD ./scripts/ /home/root/scripts

RUN npm cache clean

RUN npm install
#RUN cd /app && npm run build
#RUN ln -sf /usr/local/openresty/nginx/html /app/html
#RUN cp -aRv /app/dist/* /app/html

EXPOSE 80 443 4444 5999

#ADD nginx/nginx.conf /etc/nginx/nginx.conf
#ADD nginx/default.conf /etc/nginx/conf.d/default.conf

# Expose volumes.
#VOLUME ["/etc/nginx"]

# Set the entrypoint script.
#ENTRYPOINT ["./entrypoint"]

# Define the default command.
#CMD ["nginx", "-c", "/etc/nginx/nginx.conf"]

#ENTRYPOINT ["sh", "/home/root/scripts/start.sh"]