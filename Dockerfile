# Neo4j Community: one database, which is all this image serves, with nothing
# from Enterprise in use -- so no Enterprise licence to accept.
FROM neo4j:4.4.48-community

# APOC for the same Neo4j minor version, fetched at build time and checked
# against its known digest rather than committed to the repository.
# From https://github.com/neo4j-contrib/neo4j-apoc-procedures/releases
ARG APOC_VERSION=4.4.0.40
ARG APOC_SHA256=3ecb3bda4d4b1659a4dd0e02d75d7c3df44bbcee1354c4cb01527a6f807733ab
ADD https://github.com/neo4j-contrib/neo4j-apoc-procedures/releases/download/${APOC_VERSION}/apoc-${APOC_VERSION}-all.jar plugins/
RUN echo "${APOC_SHA256}  plugins/apoc-${APOC_VERSION}-all.jar" | sha256sum -c - \
    && chmod 644 plugins/apoc-${APOC_VERSION}-all.jar

RUN echo 'dbms.default_database=graph.db' >> /var/lib/neo4j/conf/neo4j.conf
RUN echo 'dbms.security.auth_enabled=false' >> /var/lib/neo4j/conf/neo4j.conf
RUN echo 'dbms.tx_state.memory_allocation=OFF_HEAP' >> /var/lib/neo4j/conf/neo4j.conf
RUN echo 'dbms.tx_state.max_off_heap_memory=0' >> /var/lib/neo4j/conf/neo4j.conf
RUN echo 'dbms.tx_log.rotation.retention_policy=false' >> /var/lib/neo4j/conf/neo4j.conf
RUN echo 'dbms.tx_log.preallocate=false' >> /var/lib/neo4j/conf/neo4j.conf
RUN echo 'dbms.import.csv.buffer_size=134217728' >> /var/lib/neo4j/conf/neo4j.conf
RUN echo 'dbms.connector.bolt.thread_pool_min_size=20' >> /var/lib/neo4j/conf/neo4j.conf
RUN echo 'dbms.connector.bolt.thread_pool_max_size=100' >> /var/lib/neo4j/conf/neo4j.conf
RUN echo 'dbms.connector.bolt.thread_pool_keep_alive=10m' >> /var/lib/neo4j/conf/neo4j.conf
RUN echo 'dbms.security.procedures.unrestricted=algo.*,apoc.*' >> /var/lib/neo4j/conf/neo4j.conf
RUN echo 'cypher.min_replan_interval=120000ms' >> /var/lib/neo4j/conf/neo4j.conf
RUN echo 'cypher.statistics_divergence_threshold=0.9' >> /var/lib/neo4j/conf/neo4j.conf
RUN echo 'dbms.connector.bolt.address=0.0.0.0:7687' >> /var/lib/neo4j/conf/neo4j.conf

ARG NEO4J_AUTH=none
ENV NEO4J_AUTH ${NEO4J_AUTH}

ARG NEO4J_dbms_connectors_default__listen__address=0.0.0.0
ENV NEO4J_dbms_connectors_default__listen__address ${NEO4J_dbms_connectors_default__listen__address}
