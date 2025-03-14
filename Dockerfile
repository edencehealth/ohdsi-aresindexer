FROM edence/ohdsi-achilles:1

USER root
WORKDIR /app

COPY patches/. /patches/
RUN /patches/run.sh

RUN set -eux; \
  /patches/run.sh; \
  Rscript \
  -e "renv::install(c('OHDSI/Achilles@develop', 'OHDSI/AresIndexer@develop', 'OHDSI/Castor'))" \
  ;

COPY assets assets/
COPY ares.R wrapper_functions.R entrypoint.sh ./

USER nonroot
ENTRYPOINT ["/app/entrypoint.sh"]
