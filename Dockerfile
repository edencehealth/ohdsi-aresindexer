FROM edence/ohdsi-achilles

USER root
WORKDIR /app

RUN Rscript \
    -e "renv::install('OHDSI/AresIndexer')" \
    -e "renv::install('OHDSI/Castor')" \
  ;

COPY ares.R  entrypoint.sh ./

ENTRYPOINT ["bash", "/app/entrypoint.sh"]
