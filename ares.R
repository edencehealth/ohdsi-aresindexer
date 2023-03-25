#!/usr/bin/Rscript
# Wrapper around OHDSI Ares(Indexer) to generate output needed for Ares Visualization
# edenceHealth NV <info@edence.health>

aresDataRoot <- "/webserver_root/ares/data"
cdmVersion <- Sys.getenv("CDM_VERSION")
cdmDatabaseSchema <- Sys.getenv("CDM_SCHEMA")
resultsDatabaseSchema <- Sys.getenv("RESULTS_SCHEMA")
vocabDatabaseSchema <- Sys.getenv("CDM_SCHEMA")
cdmSourceName <- Sys.getenv("CDM_SOURCE")

# retrieve environment settings
dbms <- Sys.getenv("DB_DBMS")
server  <- paste(Sys.getenv("DB_HOSTNAME"), Sys.getenv("DB_NAME"), sep = "/")
user <- Sys.getenv("DB_USERNAME")
password <- Sys.getenv("DB_PASSWORD")
pathToDriver <- "/usr/local/lib/DatabaseConnectorJars"

# configure connection
connectionDetails <- DatabaseConnector::createConnectionDetails(
   dbms     = dbms,
   server   = server,
   user     = user,
   password = password,
   pathToDriver = pathToDriver
)

# run achilles
Achilles::achilles(
   cdmVersion = cdmVersion,
   connectionDetails = connectionDetails,
   cdmDatabaseSchema = cdmDatabaseSchema,
   resultsDatabaseSchema = resultsDatabaseSchema
)

# obtain the data source release key (naming convention for folder structures)
releaseKey <- AresIndexer::getSourceReleaseKey(connectionDetails, cdmDatabaseSchema)
datasourceReleaseOutputFolder <- file.path(aresDataRoot, releaseKey)

# run data quality dashboard and output results to data source release folder in ares data folder
dqResults <- DataQualityDashboard::executeDqChecks(
   connectionDetails = connectionDetails,
   cdmDatabaseSchema = cdmDatabaseSchema,
   resultsDatabaseSchema = resultsDatabaseSchema,
   vocabDatabaseSchema = cdmDatabaseSchema,
   cdmVersion = cdmVersion,
   cdmSourceName = cdmSourceName,
   outputFile = "dq-result.json",
   outputFolder = datasourceReleaseOutputFolder
)

# export the achilles results to the ares folder
Achilles::exportAO(
   connectionDetails = connectionDetails,
   cdmDatabaseSchema = cdmDatabaseSchema,
   resultsDatabaseSchema = resultsDatabaseSchema,
   vocabDatabaseSchema = vocabDatabaseSchema,
   outputPath = aresDataRoot
)

# perform temporal characterization
outputFile <- file.path(datasourceReleaseOutputFolder, "temporal-characterization.csv")
Achilles::performTemporalCharacterization(
   connectionDetails = connectionDetails,
   cdmDatabaseSchema = cdmDatabaseSchema,
   resultsDatabaseSchema = resultsDatabaseSchema,
   outputFile = outputFile
)

# augment concept files with temporal characterization data
AresIndexer::augmentConceptFiles(releaseFolder = file.path(aresDataRoot, releaseKey))

# build network level index for all existing sources
sourceFolders <- list.dirs(aresDataRoot,recursive=F)
AresIndexer::buildNetworkIndex(sourceFolders = sourceFolders, outputFolder = aresDataRoot)
AresIndexer::buildDataQualityIndex(sourceFolders = sourceFolders, outputFolder = aresDataRoot)
AresIndexer::buildNetworkUnmappedSourceCodeIndex(sourceFolders = sourceFolders, outputFolder = aresDataRoot)
