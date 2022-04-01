FROM public.ecr.aws/geoschem-wustl/geoschem_benchmark:latest

# install some prereqs
RUN yum install -y \
    emacs \
    wget \
    time

# set default workdir
WORKDIR /

# add spack environment
ENV SPACK_ROOT="/opt/spack"

# copy various run scripts
ADD scripts /scripts
ADD environments /environments

# make run scripts executable
RUN chmod -R +x /scripts/

# default command does nothing -- this is useful for testing
CMD [ "./scripts/runForever.sh" ]

# TODO switch to using non-root user and workdir to non /
