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
COPY createRunDir.sh /createRunDir.sh
COPY runForever.sh /runForever.sh
COPY runBenchmark.sh /runBenchmark.sh
COPY gchp_source.env gchp_source.env
COPY gchp.cloud.run gchp.cloud.run

# make files executable
RUN chmod +x /createRunDir.sh \ 
    && chmod +x /runForever.sh \
    && chmod +x /runBenchmark.sh
    
ENV SPACK_ROOT="/opt/spack"
# default does nothing
CMD [ "./runForever.sh" ]

# TODO switch to using non-root user
