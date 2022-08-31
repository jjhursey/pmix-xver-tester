# ------------------------------------------------------------
# OS: RHEL UBI 8
# ------------------------------------------------------------
FROM redhat/ubi8

# ------------------------------------------------------------
# Metadata
# ------------------------------------------------------------
LABEL maintainer="jjhursey@open-mpi.org"

ARG _BUILD_FLEX_VERSION=2.6.4
ARG _BUILD_HWLOC_VERSION=2.8.0
ARG _BUILD_HWLOC1_VERSION=1.11.13
ARG _BUILD_LIBEVENT_VERSION=2.1.12

ARG LIBEVENT_INSTALL_PATH=/home/pmixer/local/libevent
ARG HWLOC1_INSTALL_PATH=/home/pmixer/local/hwloc-1x
ARG HWLOC_INSTALL_PATH=/home/pmixer/local/hwloc

LABEL com.ibm.hwloc.version=${_BUILD_HWLOC_VERSION}
LABEL com.ibm.hwloc1.version=${_BUILD_HWLOC1_VERSION}
LABEL com.ibm.libevent.version=${_BUILD_LIBEVENT_VERSION}

# ------------------------------------------------------------
# Install required packages
#    yum -y install epel-release && \
# ------------------------------------------------------------
RUN yum -y update && \
    yum -y install \
        gcc gcc-gfortran gcc-c++ \
        binutils less wget which make file \
        wget git autoconf automake libtool \
        perl perl-Data-Dumper \
        bzip2 \
        python3 \
        python3-devel \
        zlib-devel \
 && \
    if [[ ! -f /usr/bin/python ]] ; then cd /usr/bin/ && ln -s python3 python ; fi && \
    mkdir -p /opt/hpc/src && \
    yum clean all


# -----------------------------
# Add a user, so we don't run as root
# -----------------------------
RUN groupadd -g 1000 -r pmixer && \
    useradd -u 1000 --no-log-init -r -m -b /home -g pmixer pmixer && \
    echo "pmixer:pmixer" | chpasswd
USER pmixer
WORKDIR /home/pmixer

ADD --chown=pmixer:pmixer src /opt/hpc/src


# -----------------------------
# Install Flex
# -----------------------------
USER root
ARG FLEX_INSTALL_PATH=/opt/hpc/local/flex
ENV FLEX_INSTALL_PATH=$FLEX_INSTALL_PATH

RUN cd /tmp && \
    tar -zxf /opt/hpc/src/flex-${_BUILD_FLEX_VERSION}.tar.gz && \
    cd flex-${_BUILD_FLEX_VERSION} && \
    ./configure --prefix=${FLEX_INSTALL_PATH} && \
    make && \
    make install && \
    cd / && rm -rf /tmp/flex*

ENV PATH="$FLEX_INSTALL_PATH/bin:${PATH}"
ENV LD_LIBRARY_PATH="$FLEX_INSTALL_PATH/lib:${LD_LIBRARY_PATH}"

RUN echo "export PATH=$FLEX_INSTALL_PATH/bin:\$PATH" >> /etc/bashrc && \
    echo "export LD_LIBRARY_PATH=$FLEX_INSTALL_PATH/lib:\$LD_LIBRARY_PATH" >> /etc/bashrc


# -----------------------------
# Cython
# -----------------------------
USER pmixer
ENV AUTOMAKE_JOBS=20

RUN git config --global pull.ff only && \
    pip3 install --user Cython

ENV PYTHONPATH=/home/pmixer/.local/lib/python3.6/site-packages


# -----------------------------
# Install libevent and hwloc (both 2.x and 1.x)
# -----------------------------
RUN mkdir -p /home/pmixer/local

ENV LIBEVENT_INSTALL_PATH=$LIBEVENT_INSTALL_PATH
ENV HWLOC1_INSTALL_PATH=$HWLOC1_INSTALL_PATH
ENV HWLOC_INSTALL_PATH=$HWLOC_INSTALL_PATH

RUN cd /home/pmixer/local && \
    mkdir build && \
    cd build && \
    tar -zxf /opt/hpc/src/libevent-${_BUILD_LIBEVENT_VERSION}-stable.tar.gz && \
    cd libevent* && \
    ./configure --prefix=${LIBEVENT_INSTALL_PATH} --disable-openssl > /dev/null && \
    make > /dev/null && \
    make install > /dev/null && \
    cd /home/pmixer/local/build && \
    tar -zxf /opt/hpc/src/hwloc-${_BUILD_HWLOC1_VERSION}.tar.gz && \
    cd hwloc-${_BUILD_HWLOC1_VERSION} && \
    ./configure --prefix=${HWLOC1_INSTALL_PATH} > /dev/null && \
    make > /dev/null && \
    make install > /dev/null && \
    cd /home/pmixer/local/build && \
    tar -zxf /opt/hpc/src/hwloc-${_BUILD_HWLOC_VERSION}.tar.gz && \
    cd hwloc-${_BUILD_HWLOC_VERSION} && \
    ./configure --prefix=${HWLOC_INSTALL_PATH} > /dev/null && \
    make > /dev/null && \
    make install > /dev/null && \
    cd .. && \
    rm -rf build


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
RUN mkdir -p /home/pmixer/scratch && \
    cd /home/pmixer/pmix-tests/crossversion && \
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
