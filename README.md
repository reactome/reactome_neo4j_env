# Reactome Data Image Generation Documentation

This repository does not follow the standard AGR branching strategy, but instead adopts a NEO4j release based branching as `neo-x.y`.
In doing so, it supports an automatic stable GoCD build from such NEO4j versioned branch(es) for use in the staging (and production) environments, while enabling testing of new NEO4j versions on the build environment (on other branches). Any updates within a neo4j release should be done on the matching `neo-x.y` branch, and then merged into master.

## Neo4j edition and plugins

The image is built on **Neo4j Community 4.4** (`neo4j:4.4.48-community`). It serves one
database, `graph.db`, and uses nothing from Enterprise, so there is no Enterprise licence
to accept. APOC is fetched at build time for the matching Neo4j minor version and checked
against its SHA-256 (`APOC_VERSION` / `APOC_SHA256` in the `Dockerfile`); to move to a new
APOC release, change both.

A dump produced by an older 4.x release loads with `neo4j-admin load` as before. Queries
without an `ORDER BY` can return rows in a different order on a different Neo4j version,
so clients that compare answers byte for byte should compare against the same database.

After a version has been created, the user should create a tagged docker container with the following command

```bash
make all VERSION=<version>
make push VERSION=<version>
```
This will make it so that there is a graphdb_env container available via ECR (by default). If you would like to use this version feel free to specify the version in the add_data's Dockerfile or just use latest.   

In order to make changes and test them you might want to create a "develop" container. To do this you can use commands available in the Makefile:

*These are commands done on the development machine. If you are developing locally feel free to use the commands but don't push to ECR

## Building develop container
```bash
make create-data-image
```

## Make data image
```bash
make create-data-image
```

## Share by pushing to container registry
```bash
 make push-to-dockerhub VERSION=<VERSION>
```

## Using develop container from container registry
```bash
make pull
```

### Make readonly container for production
```bash
make create-data-image VERSION=<version>
```

## Running Bash inside container
```bash
make bash
```

## Run data container
```bash
make run
```

### Making Queries

Either go to Localhost:7474 and browse using the UI or use the bolt port within an application
