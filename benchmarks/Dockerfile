FROM geoschem/gchp:13.3.4

# install some prereqs
RUN apt-get update \
    && apt-get install -y \
        python \
        python3 \
        python3-pip \
        python3-setuptools \
        wget\
        sudo\
    && pip3 install --upgrade pip \
    && apt-get clean
RUN pip3 --no-cache-dir install --upgrade awscli
RUN cd home && \
    git clone https://github.com/LiamBindle/bashdatacatalog.git .bashdatacatalog
ENV PATH="/home/.bashdatacatalog:${PATH}"

# update spack and install gettext
ENV SPACK_ROOT="/opt/spack"
RUN cd /opt/spack && git pull
RUN . /opt/spack/share/spack/setup-env.sh && spack install --reuse gettext

# copy various run scripts
ADD scripts /scripts
ADD environments /environments

# remove old gc code
RUN rm -rf /gc-src

# make run scripts executable
RUN chmod -R +x /scripts/
    
# default command does nothing -- this is useful for testing
CMD [ "./scripts/runForever.sh" ]

# TODO switch to using non-root user
