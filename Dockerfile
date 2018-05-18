FROM neo4j:3.4-enterprise

ADD neo4j-graphql-0.1-SNAPSHOT.jar plugins
ADD apoc-3.4.0.1-all.jar plugins

RUN echo 'dbms.unmanaged_extension_classes=org.neo4j.graphql=/graphql' >> /var/lib/neo4j/conf/neo4j.conf
RUN echo 'dbms.security.auth_enabled=false' >> /var/lib/neo4j/conf/neo4j.conf
RUN echo 'dbms.memory.pagecache.size=8g' >> /var/lib/neo4j/conf/neo4j.conf

ARG NEO4J_ACCEPT_LICENSE_AGREEMENT=yes
ENV NEO4J_ACCEPT_LICENSE_AGREEMENT ${NEO4J_ACCEPT_LICENSE_AGREEMENT}

ARG NEO4J_AUTH=none
ENV NEO4J_AUTH ${NEO4J_AUTH}

ARG NEO4J_dbms_connectors_default__listen__address=0.0.0.0
ENV NEO4J_dbms_connectors_default__listen__address ${NEO4J_dbms_connectors_default__listen__address}

#RUN rm data
#RUN mkdir -p data/databases/graph.db
#RUN chown -R neo4j.neo4j data
