#######################################################################
# Dockerfile to build Kaldi (speech recognition engine container image
# Based on Ubuntu + SRILM
#######################################################################

FROM debian:8

################## BEGIN INSTALLATION ######################

RUN apt-get update && apt-get install -y  \
    autoconf \
    automake \
    libtool-bin \
    make \
    gcc \
    g++ \
    gfortran \
    git \
    subversion \
    curl \
    wget \
    libjson0 \
    libjson0-dev \
    zlib1g-dev \
    bzip2 \
    gsl-bin libgsl0ldbl \
    libatlas3-base \
    glpk-utils \
    libglib2.0-dev

RUN apt-get update && apt-get install -y  \
    python2.7 \
    python-pip \
    python-yaml \
    python-simplejson \
    python-gi \
    python-software-properties && \
    pip install ws4py==0.3.2 && \
    pip install tornado && \
    ln -s /usr/bin/python2.7 /usr/bin/python ; ln -s -f bash /bin/sh

#------ Kaldi ----
WORKDIR /

RUN echo "===> install Kaldi (latest from source)"  && \
    git clone https://github.com/kaldi-asr/kaldi && \
    cd /kaldi/tools && \
    make && \
    ./install_portaudio.sh && \
    cd /kaldi/src && ./configure --shared && \
    sed -i '/-g # -O0 -DKALDI_PARANOID/c\-O3 -DNDEBUG' kaldi.mk && \
    make depend && make && \
    cd /kaldi/src/online && make depend && make

COPY srilm-1.7.2.tar.gz /kaldi/tools/srilm.tgz

WORKDIR /kaldi/tools

RUN apt-get install gawk && \
    chmod +x extras/* && \
    ./extras/install_liblbfgs.sh && \
    ./extras/install_srilm.sh && \
    chmod +x env.sh && \
    source ./env.sh

WORKDIR /tmp

# Add python 3.6
RUN wget https://www.python.org/ftp/python/3.6.1/Python-3.6.1.tgz && \
    tar xvf Python-3.6.1.tgz && \
    cd Python-3.6.1 && \
    ./configure --enable-optimizations && \
    make -j8 && \
    make altinstall

# Add python packages and their dependencies
RUN apt-get install -y python-dev python3-pip && \
    pip3 install numpy && \
    pip3.6 install git+https://github.com/jiaaro/pydub.git@master && \
    pip3.6 install git+https://github.com/dopefishh/pympi.git@master

# Add a task runner
RUN wget https://github.com/go-task/task/releases/download/v1.3.1/task_1.3.1_linux_x64.tar.gz && \
    tar xzf task_1.3.1_linux_x64.tar.gz && \
    mv task /usr/local/bin/task

# Add jq
RUN wget https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 && \
    chmod +x jq-linux64 && \
    mv jq-linux64 /usr/local/bin/jq

# Add node, npm and xml-js
RUN apt-get install -y nodejs build-essential npm && \
    ln -s /usr/bin/nodejs /usr/bin/node && \
    npm install -g xml-js

# Add moutsache templates as mo
RUN curl -sSO https://raw.githubusercontent.com/tests-always-included/mo/master/mo && \
    chmod +x mo && \
    mv mo /usr/local/bin

#----- Cleaning up package manager
RUN apt-get clean autoclean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

RUN pwd && git clone https://github.com/CoEDL/kaldi-helpers.git /kaldi-helpers

WORKDIR /kaldi-helpers

# Add random number generator to skip Docker building cache
ADD http://www.random.org/strings/?num=10&len=8&digits=on&upperalpha=on&loweralpha=on&unique=on&format=plain&rnd=new /uuid
RUN git pull
