# Reactome Data Image Generation Documentation

This repository does not follow the standard AGR branching strategy, but instead adopts a NEO4j release based branching as `neo-x.y`.
In doing so, it supports an automatic stable GoCD build from such NEO4j versioned branch(es) for use in the staging (and production) environments, while enabling testing of new NEO4j versions on the build environment (on other branches). Any updates within a neo4j release should be done on the matching `neo-x.y` branch, and then merged into master.

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

## Extracting the schema for reactome-mcp

[`reactome-mcp`](https://github.com/reactome/reactome-mcp) consumes a baked JSON schema so MCP clients (Claude Code, Claude Desktop) can introspect the graph without a live DB round-trip. Regenerate the artifact whenever you build a new data image:

```bash
# 1. start the data image
make run  # or: docker run -p 7474:7474 -p 7687:7687 <image>

# 2. extract (requires curl + jq on the host)
make extract-schema VERSION=<release>
# writes schemas/reactome-<release>.json
```

The artifact captures:

- `apoc.meta.schema()` — labels, relationship cardinalities, per-property types
- `apoc.meta.stats()` — node / relationship counts per type
- `apoc.meta.nodeTypeProperties()` / `apoc.meta.relTypeProperties()` — full per-label and per-rel property inventories with mandatory flags
- `db.indexes()` / `db.constraints()` — current indexes and constraints
- `dbms.components()` — Neo4j version metadata

Commit the generated JSON alongside the release. `reactome-mcp` vendors a copy; refresh it there too when the schema changes.

### Ship the schema inside the data image

Once the JSON is in `schemas/`, layer it onto an existing data image so curators can pull it out directly from the container:

```bash
make add-schema-to-image VERSION=<release>
# builds reactome/graphdb:<release>-schema (thin layer on top of
# public.ecr.aws/reactome/graphdb:<release> — no 4 GB rebuild)
```

Run it and the schema is readable at `/reactome-schema.json`:

```bash
docker run -p 7474:7474 -p 7687:7687 -e NEO4J_dbms_memory_heap_maxSize=8g \
  reactome/graphdb:<release>-schema

docker exec <container> cat /reactome-schema.json
# or copy it to the host:
docker cp <container>:/reactome-schema.json ./schema.json
```

Image labels expose the path and version for automated tooling:

- `org.reactome.schema.path=/reactome-schema.json`
- `org.reactome.schema.version=<release>`

To layer onto a locally-built image instead of the public ECR tag, pass `SCHEMA_BASE=reactome/graphdb`.
