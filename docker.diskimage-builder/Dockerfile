FROM ubuntu:16.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends apt-transport-https ca-certificates curl bsdtar

# RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D 

RUN curl https://apt.dockerproject.org/gpg > docker.gpg.key \
 && echo "c836dc13577c6f7c133ad1db1a2ee5f41ad742d11e4ac860d8e658b2b39e6ac1 docker.gpg.key" | sha256sum -c && apt-key add docker.gpg.key && rm docker.gpg.key

RUN echo "deb https://apt.dockerproject.org/repo ubuntu-xenial main" >> /etc/apt/sources.list

RUN apt-get update \
    && apt-get install -y --no-install-recommends apt-transport-https ca-certificates \
       qemu-utils git kpartx lzop parted python python-yaml sudo \
       uuid-runtime xfsprogs tree rsync bzip2 docker-engine vim

RUN curl https://bootstrap.pypa.io/get-pip.py | python

WORKDIR /usr/local/src

# add in our disk-image-builder src tree
ADD src /usr/local/src/diskimage-builder

RUN cd /usr/local/src/diskimage-builder \
    && pip install -r requirements.txt \
    && python setup.py build \
    && python setup.py install \
    && git clone https://github.com/openstack/dib-utils /usr/local/src/dib-utils 
# RUN mv /bin/tar /bin/tar.notused && ln -s /usr/bin/bsdtar /bin/tar

# RUN losetup

# now using bsdtar, we have issues
# https://github.com/moby/moby/issues/355
# RUN apt-get install locales && \
#     locale-gen en_AU && \
#     locale-gen en_AU.UTF-8 
