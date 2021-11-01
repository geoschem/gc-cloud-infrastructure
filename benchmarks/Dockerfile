FROM geoschem/gchp:13.2.1

COPY createRunDir.sh /createRunDir.sh
COPY gchp_source.env gchp_source.env
RUN chmod +x /createRunDir.sh \
    && apt-get update \
    && apt-get install -y \
        python3 \
        python3-pip \
        python3-setuptools \
    && pip3 install --upgrade pip \
    && apt-get clean

RUN pip3 --no-cache-dir install --upgrade awscli
ENTRYPOINT [ "./createRunDir.sh" ]
