from edence/ohdsi-achilles

USER root

RUN cd /app

WORKDIR /app


RUN set -eux; \
  Rscript \
    -e "renv::install('OHDSI/AresIndexer')" \
  ;

COPY . .

ENTRYPOINT ["bash", "/app/entrypoint.sh"]
