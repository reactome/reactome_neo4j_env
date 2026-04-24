REG := reactome
VERSION := Release86

registry-docker-login:
ifneq ($(shell echo ${REG} | egrep "ecr\..+\.amazonaws\.com"),)
	@$(eval DOCKER_LOGIN_CMD=docker run --rm -it -v ~/.aws:/root/.aws amazon/aws-cli)
ifneq (${AWS_PROFILE},)
	@$(eval DOCKER_LOGIN_CMD=${DOCKER_LOGIN_CMD} --profile ${AWS_PROFILE})
endif
	@$(eval DOCKER_LOGIN_CMD=${DOCKER_LOGIN_CMD} ecr get-login-password | docker login -u AWS --password-stdin https://${REG})
	${DOCKER_LOGIN_CMD}
endif

download-database-dump-file:
	curl -o "reactome.graphdb.dump" https://reactome.org/download/current/reactome.graphdb.dump

create-graphdb-env-image:
	docker build -t ${REG}/graphdb_env:${VERSION} .
	docker tag ${REG}/graphdb_env:${VERSION} ${REG}/graphdb_env:latest

create-data-image: create-graphdb-env-image
	docker build -t ${REG}/graphdb:${VERSION} -f ./Dockerfile_add_data .
	docker tag ${REG}/graphdb:${VERSION} ${REG}/graphdb:latest

create-readonly-image:
	docker build -t ${REG}/graphdb_readonly:${VERSION} -f ./Dockerfile_readonly .

push-to-dockerhub: registry-docker-login
	docker push ${REG}/graphdb:${VERSION}
	docker push ${REG}/graphdb:latest


pull: registry-docker-login
	docker pull ${REG}/graphdb:${VERSION}

bash:
	docker run -t -i ${REG}/graphdb:${VERSION} bash

run:
	docker run -p 7475:7474 -p 7688:7687 -e NEO4J_dbms_memory_heap_maxSize=8g ${REG}/graphdb:${VERSION}

# Extract the graph schema (labels, relationship cardinalities, property
# types, indexes, constraints) from a running Reactome Neo4j and write
# schemas/reactome-${VERSION}.json. Consumed by reactome-mcp so that MCP
# clients can get the schema without a live DB round-trip.
#
# Requires: a running container reachable on HTTP_BASE (default
# http://localhost:7474) with auth disabled (default in this image), plus
# curl and jq on the host.
#
# Usage: make extract-schema VERSION=Release96 [HTTP_BASE=http://localhost:7474]
HTTP_BASE ?= http://localhost:7474
extract-schema:
	bin/extract-schema.sh ${VERSION} ${HTTP_BASE}

# Layer schemas/reactome-${VERSION}.json onto an existing data image and
# produce ${REG}/graphdb:${VERSION}-schema. Defaults to the public ECR
# image as the base so no 4 GB local rebuild is required; override
# SCHEMA_BASE to layer onto a locally-built reactome/graphdb:${VERSION}.
#
# Usage: make add-schema-to-image VERSION=Release96 \
#            [SCHEMA_BASE=public.ecr.aws/reactome/graphdb]
SCHEMA_BASE ?= public.ecr.aws/reactome/graphdb
add-schema-to-image:
	@test -f schemas/reactome-${VERSION}.json \
		|| (echo "schemas/reactome-${VERSION}.json missing; run 'make extract-schema VERSION=${VERSION}' first" >&2; exit 1)
	docker build \
		-t ${REG}/graphdb:${VERSION}-schema \
		-f Dockerfile_with_schema \
		--build-arg VERSION=${VERSION} \
		--build-arg SCHEMA_BASE=${SCHEMA_BASE} \
		.
	@echo ""
	@echo "built ${REG}/graphdb:${VERSION}-schema — run it with:"
	@echo "  docker run -p 7474:7474 -p 7687:7687 -e NEO4J_dbms_memory_heap_maxSize=8g ${REG}/graphdb:${VERSION}-schema"
	@echo "verify the schema file with:"
	@echo "  docker exec <container> ls -la /reactome-schema.json"
