from edence/ohdsi-achilles

USER root

RUN cd /app

WORKDIR /app


RUN set -eux; \
  Rscript \
    -e "renv::install('OHDSI/AresIndexer')" \
    -e "renv::install('OHDSI/Castor')" \
  ;

COPY . .

ENTRYPOINT ["bash", "/app/entrypoint.sh"]
