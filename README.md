# ohdsi-aresindexer

Modified version of the ohdsi-achilles image that also contains the
[OHDSI/AresIndexer R package](https://github.com/OHDSI/AresIndexer), and
incorporates the [R script](https://github.com/OHDSI/Ares/blob/main/docs/index.md)
used to generate the proper data files for visualising a data source release in
the [Ares web application.](https://github.com/edencehealth/ohdsi-ares)

See the included `docker-compose.example.yml` for the configuration necessary
to deploy the image with docker compose.

> **NOTE** In the patches directory you will find two header-only csv files:
>
> - netwtork-unmapped-source-codes.csv
> - temporal-characterization.csv
>
> If you have no unmapped codes in your source, you will need to place the `network...csv` file in the data root directory for the application to function properly.
>
> If your data source does not allow for temporal characterization, you will need to place the `temporal...csv` file in the source release directory for that given source
