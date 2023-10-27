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
