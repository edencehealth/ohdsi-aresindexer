#!/usr/bin/Rscript
# Wrapper around OHDSI Ares(Indexer) to generate output needed for Ares Visualization
# edenceHealth NV <info@edence.health>

library(rlang)

inform("Assigning parameters using sys env variables")

# retrieve environment settings
aresDataRoot <- "/webserver_root/ares/data"
cdmVersion <- Sys.getenv("CDM_VERSION")
cdmDatabaseSchema <- Sys.getenv("CDM_SCHEMA")
resultsDatabaseSchema <- Sys.getenv("RESULTS_SCHEMA")
vocabDatabaseSchema <- Sys.getenv("CDM_SCHEMA")
cdmSourceName <- Sys.getenv("CDM_SOURCE")
dbms <- Sys.getenv("DB_DBMS")
server  <- paste(Sys.getenv("DB_HOSTNAME"), Sys.getenv("DB_NAME"), sep = "/")
user <- Sys.getenv("DB_USERNAME")
password <- Sys.getenv("DB_PASSWORD")
pathToDriver <- "/usr/local/lib/DatabaseConnectorJars"
runMode <- Sys.getenv("RUN_MODE") # Possible Values: SOURCE, NETWORK

if (runMode %in% c("SOURCE", "NETWORK")) {
    print(
        inform(
            paste(
                "Launching AresIndexer Process using RUN_MODE: ",
                runMode,
                ". Good Luck!",
                sep = "'"
            )
        )
    )
} else {
    stop(
        paste(
            "RUN_MODE: ",
            runMode,
            " not recognized (allowed options: 'SOURCE', 'NETWORK'). Exiting.",
            sep = "'"
        )
    )
}

if (cdmVersion == "5.4.0"){
    cdmVersion <- "5.4"
}

if (runMode == "SOURCE") {
    inform("Configuring database connection parameters")
    connectionDetails <- DatabaseConnector::createConnectionDetails(
       dbms     = dbms,
       server   = server,
       user     = user,
       password = password,
       pathToDriver = pathToDriver
    )

    inform(
        paste("Obtaining the data source release key",
        "(naming convention for folder structures)"
        )
    )

    releaseKey <- AresIndexer::getSourceReleaseKey(connectionDetails, cdmDatabaseSchema)
    datasourceReleaseOutputFolder <- file.path(aresDataRoot, releaseKey)

    inform("Launching achilles")
    Achilles::achilles(
       cdmVersion = cdmVersion,
       connectionDetails = connectionDetails,
       cdmDatabaseSchema = cdmDatabaseSchema,
       resultsDatabaseSchema = resultsDatabaseSchema
    )

    inform(
        paste(
            "Running data quality dashboard.",
            "\nOutputting results to data source release folder in ares data folder"
        )
    )

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

    inform("Exporting the achilles results to the ares folder")

    Achilles::exportAO(
       connectionDetails = connectionDetails,
       cdmDatabaseSchema = cdmDatabaseSchema,
       resultsDatabaseSchema = resultsDatabaseSchema,
       vocabDatabaseSchema = vocabDatabaseSchema,
       outputPath = aresDataRoot
    )

    inform("Performing temporal characterization")
    outputFile <- file.path(datasourceReleaseOutputFolder, "temporal-characterization.csv")
    Achilles::performTemporalCharacterization(
       connectionDetails = connectionDetails,
       cdmDatabaseSchema = cdmDatabaseSchema,
       resultsDatabaseSchema = resultsDatabaseSchema,
       outputFile = outputFile
    )

    inform("Augmenting concept files with temporal characterization data")
    AresIndexer::augmentConceptFiles(releaseFolder = file.path(aresDataRoot, releaseKey))
} else {
    inform("Building network level index for all existing sources")
    sourceFolders <- list.dirs(aresDataRoot,recursive=F)
    AresIndexer::buildNetworkIndex(sourceFolders = sourceFolders, outputFolder = aresDataRoot)
    AresIndexer::buildDataQualityIndex(sourceFolders = sourceFolders, outputFolder = aresDataRoot)
    out <- tryCatch(
    {
        inform("Creating network-level unmapped code overview")
        AresIndexer::buildNetworkUnmappedSourceCodeIndex(sourceFolders = sourceFolders, outputFolder = aresDataRoot)
    },
    error = function(cond) {
        inform("There are no unmapped codes across your network. Congratulations!")
        warn(
            paste(
                "You will need to retrieve the 'network-unmapped-source-codes.csv'",
                "\nfrom the patches directory and place it in your data root folder",
                "\nwith the other network-*.csv files for proper Ares functionality"
            )
        )
    },
    warning = function(cond) {
        message(cond)
    },
    finally = {
        inform("All processes complete! Exiting.")
    }
    )
}
