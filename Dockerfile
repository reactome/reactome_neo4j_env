FROM neo4j:4.3.6-enterprise

# From https://github.com/neo4j-contrib/neo4j-apoc-procedures/releases
ADD apoc-4.3.0.12-all.jar plugins

RUN echo 'dbms.active_database=graph.db' >> /var/lib/neo4j/conf/neo4j.conf
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

ARG NEO4J_ACCEPT_LICENSE_AGREEMENT=yes
ENV NEO4J_ACCEPT_LICENSE_AGREEMENT ${NEO4J_ACCEPT_LICENSE_AGREEMENT}

ARG NEO4J_AUTH=none
ENV NEO4J_AUTH ${NEO4J_AUTH}

ARG NEO4J_dbms_connectors_default__listen__address=0.0.0.0
ENV NEO4J_dbms_connectors_default__listen__address ${NEO4J_dbms_connectors_default__listen__address}
