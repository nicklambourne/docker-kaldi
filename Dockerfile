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
    ./env.sh

#----- Cleaning up package manager
RUN apt-get clean autoclean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /kaldi
