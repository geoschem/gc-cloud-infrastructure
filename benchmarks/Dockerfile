FROM geoschem/gchp:13.2.1

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

# copy various run scripts
ADD scripts /scripts
ADD environments /environments

# make files executable
RUN chmod +x /scripts/createRunDirGCHP.sh \ 
    && chmod +x /scripts/createRunDirGCClassic.sh \
    && chmod +x /scripts/runForever.sh \
    && chmod +x /scripts/runGCClassic.sh \
    && chmod +x /scripts/runGCHP.sh
    
ENV SPACK_ROOT="/opt/spack"

# default command does nothing -- this is useful for testing
CMD [ "./scripts/runForever.sh" ]

# TODO switch to using non-root user
