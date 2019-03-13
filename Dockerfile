FROM centos:7

LABEL maintainer="jjhursey@open-mpi.org"

RUN yum -y update && yum clean all
RUN yum -y install \
    gcc gcc-gfortran gcc-c++ \
    binutils less wget which sudo make file \
    wget git autoconf automake libtool flex \
    perl-Data-Dumper bzip2 \
    libevent hwloc


# -----------------------------
# Add a user, so we don't run as root
# -----------------------------
RUN groupadd -r pmixer && useradd --no-log-init -r -m -b /home -g pmixer pmixer
USER pmixer
WORKDIR /home/pmixer


# -----------------------------
# Install libevent and hwloc (both 2.x and 1.x)
# -----------------------------
RUN mkdir -p /home/pmixer/local
ADD --chown=pmixer:pmixer src /home/pmixer/local/src

ARG LIBEVENT_INSTALL_PATH=/home/pmixer/local/libevent
ENV LIBEVENT_INSTALL_PATH=$LIBEVENT_INSTALL_PATH
RUN cd /home/pmixer/local/src && \
    tar -zxf libevent* && \
    cd libevent* && \
    ./configure --prefix=${LIBEVENT_INSTALL_PATH} > /dev/null && \
    make > /dev/null && \
    make install > /dev/null && \
    cd ..

ARG HWLOC1_INSTALL_PATH=/home/pmixer/local/hwloc-1x
ENV HWLOC1_INSTALL_PATH=$HWLOC1_INSTALL_PATH
RUN cd /home/pmixer/local/src && \
    tar -zxf hwloc-1* && \
    cd hwloc-1* && \
    ./configure --prefix=${HWLOC1_INSTALL_PATH} > /dev/null && \
    make > /dev/null && \
    make install > /dev/null && \
    cd ..

ARG HWLOC_INSTALL_PATH=/home/pmixer/local/hwloc
ENV HWLOC_INSTALL_PATH=$HWLOC_INSTALL_PATH
RUN cd /home/pmixer/local/src && \
    tar -zxf hwloc-2* && \
    cd hwloc-2* && \
    ./configure --prefix=${HWLOC_INSTALL_PATH} > /dev/null && \
    make > /dev/null && \
    make install > /dev/null && \
    cd ..
RUN rm -rf /home/pmixer/local/src


# -----------------------------
# Checkout the pmix-tests repo
# -----------------------------
RUN cd /home/pmixer && \
    git clone https://github.com/pmix/pmix-tests
ADD --chown=pmixer:pmixer xversion.py /home/pmixer/pmix-tests/crossversion/


# -----------------------------
# Add scripts directory
# -----------------------------
ADD --chown=pmixer:pmixer bin /home/pmixer/bin


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
# Entrypoint
# -----------------------------
CMD ["/home/pmixer/bin/run-xversion.sh"]
