# ------------------------------------------------------------
# OS: Centos 7
# ------------------------------------------------------------
FROM centos:7

# ------------------------------------------------------------
# Metadata
# ------------------------------------------------------------
LABEL maintainer="jjhursey@open-mpi.org"

ARG LIBEVENT_INSTALL_PATH=/home/pmixer/local/libevent
ARG HWLOC1_INSTALL_PATH=/home/pmixer/local/hwloc-1x
ARG HWLOC_INSTALL_PATH=/home/pmixer/local/hwloc

LABEL com.ibm.hwloc.version=2.4.0
LABEL com.ibm.hwloc1.version=1.11.13
LABEL com.ibm.libevent.version=2.4.0

# ------------------------------------------------------------
# Install required packages
# ------------------------------------------------------------
RUN yum -y update && \
    yum -y install epel-release && \
    yum -y install \
        gcc gcc-gfortran gcc-c++ \
        binutils less wget which sudo make file \
        wget git autoconf automake libtool flex \
        perl-Data-Dumper bzip2 \
        pandoc python3 man \
        Cython python3-devel \
 && \
    yum clean all

# -----------------------------
# Add a user, so we don't run as root
# -----------------------------
RUN groupadd -r pmixer && useradd --no-log-init -r -m -b /home -g pmixer pmixer
USER pmixer
WORKDIR /home/pmixer

ENV AUTOMAKE_JOBS=20

# -----------------------------
# Cython
# -----------------------------
RUN pip3 install --user Cython

# -----------------------------
# Install libevent and hwloc (both 2.x and 1.x)
# -----------------------------
RUN mkdir -p /home/pmixer/local
ADD --chown=pmixer:pmixer src /home/pmixer/local/src

ENV LIBEVENT_INSTALL_PATH=$LIBEVENT_INSTALL_PATH
ENV HWLOC1_INSTALL_PATH=$HWLOC1_INSTALL_PATH
ENV HWLOC_INSTALL_PATH=$HWLOC_INSTALL_PATH

RUN cd /home/pmixer/local/src && \
    tar -zxf libevent* && \
    cd libevent* && \
    ./configure --prefix=${LIBEVENT_INSTALL_PATH} > /dev/null && \
    make > /dev/null && \
    make install > /dev/null && \
    cd /home/pmixer/local/src && \
    tar -zxf hwloc-1* && \
    cd hwloc-1* && \
    ./configure --prefix=${HWLOC1_INSTALL_PATH} > /dev/null && \
    make > /dev/null && \
    make install > /dev/null && \
    cd /home/pmixer/local/src && \
    tar -zxf hwloc-2* && \
    cd hwloc-2* && \
    ./configure --prefix=${HWLOC_INSTALL_PATH} > /dev/null && \
    make > /dev/null && \
    make install > /dev/null && \
    cd .. && \
    rm -rf /home/pmixer/local/src


# -----------------------------
# Allow forced rebuild from this point
# -----------------------------
COPY .build-timestamp /home/pmixer/


# -----------------------------
# Checkout the pmix-tests repo
# -----------------------------
RUN cd /home/pmixer && \
    git clone https://github.com/pmix/pmix-tests


# -----------------------------
# Build full set of versions
# -----------------------------
RUN mkdir -p /home/pmixer/scratch
RUN cd /home/pmixer/pmix-tests/crossversion && \
    ./xversion.py --basedir=$HOME/scratch \
         --with-hwloc=${HWLOC_INSTALL_PATH} \
         --with-hwloc1=${HWLOC1_INSTALL_PATH} \
         --with-libevent=${LIBEVENT_INSTALL_PATH} \
         -r -q


# -----------------------------
# Add scripts directory
# -----------------------------
ADD --chown=pmixer:pmixer bin /home/pmixer/bin

# -----------------------------
# Entrypoint
# -----------------------------
CMD ["/home/pmixer/bin/run-xversion.sh"]
