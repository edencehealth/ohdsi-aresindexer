FROM edence/ohdsi-achilles

USER root
WORKDIR /app

COPY patches/. /patches/
RUN /patches/run.sh

RUN Rscript \
    -e "renv::install('OHDSI/Achilles@develop')" \
    -e "renv::install('OHDSI/AresIndexer')" \
    -e "renv::install('OHDSI/Castor')" \
  ;

COPY assets assets/
COPY ares.R wrapper_functions.R entrypoint.sh ./

ENTRYPOINT ["/app/entrypoint.sh"]
