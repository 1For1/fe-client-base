#
# Openresty docker image
#
# This docker contains openresty (nginx) compiled from source with useful optional modules installed.
#
# http://github.com/tenstartups/openresty-docker
#

FROM node:6.3
MAINTAINER JobSonic "ops@1jobsonic.com"
EXPOSE 80 443 4444 5999 3000

ENV OPENRESTY_VERSION=1.9.7.2 \
  DEBIAN_FRONTEND=noninteractive \
  TERM=xterm-color \
  npm_lifecycle_event=build \
  NODE_HOST=localhost \
  NODE_PORT=3000 \
  DEBCONF_NONINTERACTIVE_SEEN=true \
  PYTHONIOENCODING=utf8 \
  LANG=en_US.UTF-8


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
  software-properties-common wget


RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
RUN echo "deb http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list
RUN apt-get update -y
RUN apt-get install -y -q \
  google-chrome-beta \
  openjdk-7-jre-headless \
  x11vnc \
  xvfb \
  xfonts-100dpi \
  xfonts-75dpi \
  xfonts-scalable \
  xfonts-cyrillic \
  python python-pip && \
  pip install honcho

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
    && mkdir -p /etc/nginx/conf.d /var/log/nginx

RUN apt-get install -y vim \
    && npm install -g webpack \
    && npm install -g typings \
    && npm install -g webdriver-manager protractor \
    && npm rebuild node-sass

# Set the working directory.
WORKDIR /app

# Add files to the container.
ADD . /app
ADD ./scripts/ /home/root/scripts

RUN npm cache clean
RUN ln -sf /usr/local/openresty/nginx/html /app/html

RUN cd $(npm root -g)/npm \
    && npm install fs-extra \
    && sed -i -e s/graceful-fs/fs-extra/ -e s/fs.rename/fs.move/ ./lib/utils/rename.js

RUN npm install \
    && npm run webdriver-manager update

#RUN npm install && npm install --only=dev