FROM geoschem/gchp:13.2.1

# install some prereqs
RUN apt-get update \
    && apt-get install -y \
        python \
        python3 \
        python3-pip \
        python3-setuptools \
    && pip3 install --upgrade pip \
    && apt-get clean
RUN pip3 --no-cache-dir install --upgrade awscli

# copy various run scripts
COPY createRunDir.sh /createRunDir.sh
COPY runForever.sh /runForever.sh
COPY runBenchmark.sh /runBenchmark.sh
COPY gchp_source.env gchp_source.env

# make files executable
RUN chmod +x /createRunDir.sh \ 
    && chmod +x /runForever.sh \
    && chmod +x /runBenchmark.sh
    
ENV SPACK_ROOT="/opt/spack"
# default does nothing
CMD [ "./runForever.sh" ]
