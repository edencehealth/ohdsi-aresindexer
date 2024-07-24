# ohdsi-aresindexer

This image is a Dockerization of the [OHDSI/AresIndexer R package](https://github.com/OHDSI/AresIndexer)'s development branch. This image also incorporates the core elements of the [suggested run script](https://github.com/OHDSI/Ares/blob/main/docs/index.md) used to generate the proper data files for the [OHDSI/Ares](https://github.com/edencehealth/ohdsi-ares) web application.

See the included `docker-compose.example.yml` for the configuration necessary to deploy the image with docker compose.

**NOTE** In the `assets` directory you will find two header-only CSV files:
- `netwtork-unmapped-source-codes.csv`
- `temporal-characterization.csv`

If you have no unmapped codes in your source, you may need to place the `network...csv` file in the data root directory for the application to function properly.
If your data source does not allow for temporal characterization, you will need to place the `temporal...csv` file in the source release directory for that given source

## Functionality

Within the `ares.R` script the following OHDSI R functions are used. Documentation for these functions can help understand what the options in the Configuration section do.

* <https://ohdsi.github.io/Achilles/reference/achilles.html>
* <https://ohdsi.github.io/Achilles/reference/exportToAres.html>
* <https://ohdsi.github.io/Achilles/reference/performTemporalCharacterization.html>
* <https://ohdsi.github.io/AresIndexer/reference/augmentConceptFiles.html>
* <https://ohdsi.github.io/AresIndexer/reference/buildDataQualityIndex.html>
* <https://ohdsi.github.io/AresIndexer/reference/buildNetworkIndex.html>
* <https://ohdsi.github.io/AresIndexer/reference/buildNetworkUnmappedSourceCodeIndex.html>
* <https://ohdsi.github.io/DataQualityDashboard/reference/executeDqChecks.html>
* <https://ohdsi.github.io/DatabaseConnector/reference/createConnectionDetails.html>

## Configuration

The following environment variables can be used to control the operation of the container at run time.

Environment Variable              | Default Value                                                                                                | Description
--------------------------------- | ------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
`ACHILLES_ANALYSIS_IDS`           | `NULL`                                                                                                       | optional comma-separated list of Achilles analysisIds for which results will be generated (defaults to all)
`ACHILLES_EXCLUDE_ANALYSIS_IDS`   | `NULL`                                                                                                       | optional comma-separated list containing the set of Achilles analyses to exclude
`ACHILLES_NUM_THREADS`            | `1`                                                                                                          | The number of threads to use to run Achilles in parallel. Default is 1 thread.
`ACHILLES_OUTPUT_FOLDER`          | `output`                                                                                                     | Path to store logs and SQL files
`ACHILLES_SMALL_CELL_COUNT`       | `5`                                                                                                          | To avoid patient identification, cells with small counts (<= smallCellCount) are deleted. Set to 0 for complete summary without small cell count restrictions. (defaults to 5)
`ARES_CONCEPT_FORMAT`             | `json`                                                                                                       | Storage format of concept data: 'json' or 'duckdb'; defaults to JSON
`ARES_DATA_ROOT`                  | `/output/ares`                                                                                               | base directory for ares data
`CDM_SCHEMA`                      | `omopcdm`                                                                                                    | name of database schema where CDM data is located
`CDM_SOURCE`                      | `cdm`                                                                                                        | name of the CDM data source (used by DataQualityDashboard)
`CDM_VERSION`                     | `5.4`                                                                                                        | OMOP CDM version number; use only major and minor version e.g. '5.3' or '5.4'
`DB_DBMS`                         | `postgresql`                                                                                                 | type of DBMS running on the server
`DB_HOSTNAME`                     | `db`                                                                                                         | the DNS hostname or address of the server to connect to
`DB_NAME`                         | `cdm`                                                                                                        | the name of the database to connect to on the database server
`DB_PASSWORD`                     | `postgres`                                                                                                   | the password to use when authenticating to the datbase server
`DB_PORT`                         | `5432`                                                                                                       | the TCP port number to use when connecting to the database server
`DB_USERNAME`                     | `postgres`                                                                                                   | the username to use when authenticating to the database server
`DQD_CHECK_LEVELS`                | `TABLE,FIELD,CONCEPT`                                                                                        | comma-separated list of DQ check levels to execute. Default is all 3: TABLE,FIELD,CONCEPT)
`DQD_CHECK_NAMES`                 | `NULL`                                                                                                       | (OPTIONAL) comma-separated list of check names to execute
`DQD_CONCEPT_CHECK_THRESHOLD_LOC` | `default`                                                                                                    | location of the threshold file for evaluating the concept checks. If not specified the default thresholds will be applied
`DQD_FIELD_CHECK_THRESHOLD_LOC`   | `default`                                                                                                    | location of the threshold file for evaluating the field checks. If not specified the default thresholds will be applied
`DQD_NUM_THREADS`                 | `1`                                                                                                          | The number of concurrent threads to use to execute the queries Default is 1 thread.
`DQD_OUTPUT_FILE`                 | `dq-result.json`                                                                                             | File to write DQD results JSON object
`DQD_TABLES_TO_EXCLUDE`           | `CONCEPT,VOCABULARY,CONCEPT_ANCESTOR,CONCEPT_RELATIONSHIP,CONCEPT_CLASS,CONCEPT_SYNONYM,RELATIONSHIP,DOMAIN` | CDM tables to exclude from the execution
`DQD_TABLE_CHECK_THRESHOLD_LOC`   | `default`                                                                                                    | location of the threshold file for evaluating the table checks. If not specified the default thresholds will be applied
`DQD_VERBOSE_MODE`                | `FALSE`                                                                                                      | determines if the console will show all DQD execution steps
`PATH_TO_DRIVER`                  | `/usr/local/lib/DatabaseConnectorJars`                                                                       | the path to the DatabaseConnectorJars directory
`RESULTS_SCHEMA`                  | `results`                                                                                                    | name of schema to write results into
`RUN_MODE`                        | `SOURCE`                                                                                                     | mode of operation; possible values: SOURCE, NETWORK
`SCRATCH_DATABASE_SCHEMA`         | `resultsDatabaseSchema`                                                                                      | schema where the vocab tables are located
`TEMP_EMULATION_DATABASE_SCHEMA`  | `resultsDatabaseSchema`                                                                                      | schema where the vocab tables are located
`VOCAB_DATABASE_SCHEMA`           | `cdmDatabaseSchema`                                                                                          | schema where the vocab tables are located
