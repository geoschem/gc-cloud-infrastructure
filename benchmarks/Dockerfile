FROM geoschem/gchp:13.2.1

COPY createRunDir.sh /createRunDir.sh
COPY gchp_source.env gchp_source.env
RUN chmod +x /createRunDir.sh \
    && apt-get update \
    && apt-get install less
ENTRYPOINT [ "./createRunDir.sh" ]
