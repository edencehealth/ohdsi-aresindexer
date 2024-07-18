#!/usr/bin/Rscript
# Wrapper around OHDSI Ares(Indexer) to generate output needed for Ares Visualization
# edenceHealth NV <info@edence.health>

# fixme: temp workaround
.libPaths(c(.libPaths(), "/usr/local/lib/R/site-library/"))

source("wrapper_functions.R")
wrapper_version_str <- "1.1"

aresDataRoot <- getcfg("ARES_DATA_ROOT", "/output/ares", "base directory for ares data")
cdmVersion <- getcfg("CDM_VERSION", "5.4", "OMOP CDM version number; use only major and minor version e.g. '5.3' or '5.4'")

cdmDatabaseSchema <- getcfg("CDM_SCHEMA", "omopcdm", "name of database schema where CDM data is located")
resultsDatabaseSchema <- getcfg("RESULTS_SCHEMA", "results", "name of schema to write results into")
vocabDatabaseSchema <- getcfg("VOCAB_DATABASE_SCHEMA", cdmDatabaseSchema, "schema where the vocab tables are located")
scratchDatabaseSchema <- getcfg("SCRATCH_DATABASE_SCHEMA", resultsDatabaseSchema, "schema where the vocab tables are located")
tempEmulationDatabaseSchema <- getcfg("TEMP_EMULATION_DATABASE_SCHEMA", resultsDatabaseSchema, "schema where the vocab tables are located")

cdmSourceName <- getcfg("CDM_SOURCE", "cdm", "name of the CDM data source (used by DataQualityDashboard)")
dbms <- getcfg("DB_DBMS", "postgresql", "type of DBMS running on the server")
hostName <- getcfg("DB_HOSTNAME", "db", "the DNS hostname or address of the server to connect to")
dbPort <- getcfg("DB_PORT", "5432", "the TCP port number to use when connecting to the database server")
dbName <- getcfg("DB_NAME", "cdm", "the name of the database to connect to on the database server")
user <- getcfg("DB_USERNAME", "postgres", "the username to use when authenticating to the database server")
password <- getcfg("DB_PASSWORD", "postgres", "the password to use when authenticating to the datbase server")
pathToDriver <- getcfg("PATH_TO_DRIVER", "/usr/local/lib/DatabaseConnectorJars", "the path to the DatabaseConnectorJars directory")

runMode <- getcfg("RUN_MODE", "SOURCE", "mode of operation; possible values: SOURCE, NETWORK")
achillesAnalysisIds <- getcfg("ACHILLES_ANALYSIS_IDS", NULL, "optional comma-separated list of Achilles analysisIds for which results will be generated (defaults to all)")
achillesExcludeAnalysisIds <- getcfg("ACHILLES_EXCLUDE_ANALYSIS_IDS", NULL, "optional comma-separated list containing the set of Achilles analyses to exclude")
achillesSmallCellCount <- getcfg("ACHILLES_SMALL_CELL_COUNT", 5, "To avoid patient identification, cells with small counts (<= smallCellCount) are deleted. Set to 0 for complete summary without small cell count restrictions. (defaults to 5)")
achillesNumThreads <- getcfg("ACHILLES_NUM_THREADS", 1, "The number of threads to use to run Achilles in parallel. Default is 1 thread.")
achillesOutputFolder <- getcfg("ACHILLES_OUTPUT_FOLDER", "output", "Path to store logs and SQL files")

dqdNumThreads <- getcfg("DQD_NUM_THREADS", 1, "The number of concurrent threads to use to execute the queries Default is 1 thread.")
dqdOutputFile <- getcfg("DQD_OUTPUT_FILE", "dq-result.json", "File to write DQD results JSON object")
dqdVerboseMode <- getcfg("DQD_VERBOSE_MODE", FALSE, "determines if the console will show all DQD execution steps")

dqdCheckLevels <- parseListArg(getcfg("DQD_CHECK_LEVELS", "TABLE,FIELD,CONCEPT", "comma-separated list of DQ check levels to execute. Default is all 3: TABLE,FIELD,CONCEPT)"))
dqdCheckNames <- getcfg("DQD_CHECK_NAMES", NULL,"(OPTIONAL) comma-separated list of check names to execute")
dqdTablesToExclude <- parseListArg(getcfg("DQD_TABLES_TO_EXCLUDE", "CONCEPT,VOCABULARY,CONCEPT_ANCESTOR,CONCEPT_RELATIONSHIP,CONCEPT_CLASS,CONCEPT_SYNONYM,RELATIONSHIP,DOMAIN", "CDM tables to exclude from the execution"))
dqdTableCheckThresholdLoc <- getcfg("DQD_TABLE_CHECK_THRESHOLD_LOC", "default", "location of the threshold file for evaluating the table checks. If not specified the default thresholds will be applied")
dqdFieldCheckThresholdLoc <- getcfg("DQD_FIELD_CHECK_THRESHOLD_LOC", "default", "location of the threshold file for evaluating the field checks. If not specified the default thresholds will be applied")
dqdConceptCheckThresholdLoc <- getcfg("DQD_CONCEPT_CHECK_THRESHOLD_LOC", "default", "location of the threshold file for evaluating the concept checks. If not specified the default thresholds will be applied")

if (runMode %in% c("SOURCE", "NETWORK")) {
  message(sprintf("starting in %s mode", runMode))
} else {
  stop(sprintf("FATAL: unknown run mode: '%s'", runMode))
}

if (cdmVersion == "5.4.0") {
  cdmVersion <- "5.4"
}

if (runMode == "SOURCE") {
  # https://ohdsi.github.io/DatabaseConnector/reference/createConnectionDetails.html
  # some drivers packages need the database name appended to the server argument
  # see ?createConnectionDetails after loading library(Achilles)
  if (dbms %in% name_concat_dbms) {
    server <- paste(hostName, dbName, sep = "/")
  } else {
    server <- hostName
  }
  cnxn <- DatabaseConnector::createConnectionDetails(
    dbms     = dbms,
    user     = user,
    password = password,
    server   = server,
    port     = dbPort,
    pathToDriver = pathToDriver
  )

  releaseKey <- AresIndexer::getSourceReleaseKey(cnxn, cdmDatabaseSchema)
  outputFolder <- file.path(aresDataRoot, releaseKey)
  message(sprintf("output folder: %s", outputFolder))

  # https://ohdsi.github.io/Achilles/reference/achilles.html
  achillesArgs = list(
    connectionDetails = cnxn,
    cdmDatabaseSchema = cdmDatabaseSchema,
    resultsDatabaseSchema = resultsDatabaseSchema,
    scratchDatabaseSchema = scratchDatabaseSchema,
    vocabDatabaseSchema = vocabDatabaseSchema,
    tempEmulationSchema = tempEmulationDatabaseSchema,
    sourceName = cdmSourceName,
    createTable = TRUE,
    smallCellCount = achillesSmallCellCount,
    cdmVersion = cdmVersion,
    createIndices = !(dbms %in% no_index_dbms),
    numThreads = achillesNumThreads,
    tempAchillesPrefix = "tmpach",
    dropScratchTables = TRUE,
    sqlOnly = FALSE,
    outputFolder = achillesOutputFolder,
    verboseMode = TRUE,
    optimizeAtlasCache = FALSE,
    defaultAnalysesOnly = TRUE,
    updateGivenAnalysesOnly = FALSE
  )
  if (!is.null(achillesAnalysisIds) && achillesAnalysisIds != "") {
    achillesArgs <- c(achillesArgs, list(analysisIds=parseListArg(achillesAnalysisIds)))
  }
  if (!is.null(achillesExcludeAnalysisIds) && achillesExcludeAnalysisIds != "") {
    achillesArgs <- c(achillesArgs, list(excludeAnalysisIds=parseListArg(achillesExcludeAnalysisIds)))
  }
  message("Achilles::achilles")
  do.call(Achilles::achilles, achillesArgs)


  # https://ohdsi.github.io/DataQualityDashboard/reference/executeDqChecks.html
  dqdArgs = list(
    connectionDetails = cnxn,
    cdmDatabaseSchema = cdmDatabaseSchema,
    resultsDatabaseSchema = resultsDatabaseSchema,
    vocabDatabaseSchema = vocabDatabaseSchema,
    cdmSourceName = cdmSourceName,
    numThreads = dqdNumThreads,
    sqlOnly = FALSE,
    outputFolder = outputFolder,
    outputFile = dqdOutputFile,
    verboseMode = dqdVerboseMode,
    writeToTable = TRUE,
    writeTableName = "dqdashboard_results",
    writeToCsv = FALSE,
    csvFile = "",
    checkLevels = dqdCheckLevels,
    cohortDefinitionId = c(),
    cohortDatabaseSchema = resultsDatabaseSchema,
    cohortTableName = "cohort",
    tablesToExclude = dqdTablesToExclude,
    cdmVersion = cdmVersion,
    tableCheckThresholdLoc = dqdTableCheckThresholdLoc,
    fieldCheckThresholdLoc = dqdFieldCheckThresholdLoc,
    conceptCheckThresholdLoc = dqdConceptCheckThresholdLoc
  )
  if (!is.null(dqdCheckNames) && dqdCheckNames != "") {
    dqdArgs <- c(dqdArgs, list(checkNames=parseListArg(dqdCheckNames)))
  }
  message(sprintf("DataQualityDashboard::executeDqChecks"))
  dqResults <- do.call(DataQualityDashboard::executeDqChecks, dqdArgs)

  # https://ohdsi.github.io/Achilles/reference/exportToAres.html
  message("Achilles::exportToAres")
  Achilles::exportToAres(
    connectionDetails = cnxn,
    cdmDatabaseSchema = cdmDatabaseSchema,
    resultsDatabaseSchema = resultsDatabaseSchema,
    vocabDatabaseSchema = vocabDatabaseSchema,
    outputPath = aresDataRoot
  )

  tryCatch(
    expr = {
      # https://ohdsi.github.io/Achilles/reference/performTemporalCharacterization.html
      message("Achilles::performTemporalCharacterization")
      Achilles::performTemporalCharacterization(
        connectionDetails = cnxn,
        cdmDatabaseSchema = cdmDatabaseSchema,
        resultsDatabaseSchema = resultsDatabaseSchema,
        analysisIds = NULL,
        conceptId = NULL,
        outputFile = file.path(outputFolder, "temporal-characterization.csv")
      )

      # https://ohdsi.github.io/AresIndexer/reference/augmentConceptFiles.html
      message("AresIndexer::augmentConceptFiles; (Augmenting concept files with temporal characterization data)")
      AresIndexer::augmentConceptFiles(releaseFolder = outputFolder)
    },
    error = function(cond) {
      warning(
          "Your data does not support temporal characterization.\n",
          cond, "\n",
          "You will need to retrieve the 'temporal-characterization.csv'\n",
          "from the assets directory and place it in your data source release folder\n",
          "with the other *.json and *.csv files for proper Ares functionality\n"
        )
    },
    warning = function(cond) {
      message(cond)
    },
    finally = {
      message("All processes complete. Exiting.")
    }
  )

  # experimenting with fall-thru
  # quit(status=0)
}

# Network mode
sourceFolders <- list.dirs(aresDataRoot, recursive = F)

# https://ohdsi.github.io/AresIndexer/reference/buildNetworkIndex.html
message("AresIndexer::buildNetworkIndex")
AresIndexer::buildNetworkIndex(
  sourceFolders = sourceFolders,
  outputFolder = aresDataRoot
)

# https://ohdsi.github.io/AresIndexer/reference/buildDataQualityIndex.html
message("AresIndexer::buildDataQualityIndex")
AresIndexer::buildDataQualityIndex(
  sourceFolders = sourceFolders,
  outputFolder = aresDataRoot
)

tryCatch(
  expr = {
    # https://ohdsi.github.io/AresIndexer/reference/buildNetworkUnmappedSourceCodeIndex.html
    message("AresIndexer::buildNetworkUnmappedSourceCodeIndex - Creating network-level unmapped code overview")
    AresIndexer::buildNetworkUnmappedSourceCodeIndex(
      sourceFolders = sourceFolders,
      outputFolder = aresDataRoot
    )
  },
  error = function(cond) {
    warning(
      "There are no unmapped codes across your network. Congratulations!\n"
      "You will need to retrieve the 'network-unmapped-source-codes.csv'\n",
      "from the assets directory and place it in your data root folder\n",
      "with the other network-*.csv files for proper Ares functionality\n"
    )
  },
  warning = function(cond) {
    message(cond)
  },
  finally = {
    message("All processes complete! Exiting.")
  }
)
