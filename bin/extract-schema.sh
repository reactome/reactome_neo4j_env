#!/usr/bin/env bash
#
# Extract a rich Reactome graph schema from a running Neo4j container and
# write it as a JSON artifact under schemas/. The output is consumed by
# reactome-mcp so the schema is available to MCP clients without a live
# DB round-trip — faster, offline-capable, and independent of APOC being
# installed on the curator's machine.
#
# Usage:
#   bin/extract-schema.sh <version> [http_base] [database]
#
# Example:
#   bin/extract-schema.sh Release96 http://localhost:7474 graph.db
#
# Requirements: curl, jq. A Reactome graphdb container must already be
# running and reachable at $HTTP_BASE. Auth must be disabled (as in the
# reactome_neo4j_env image defaults).

set -euo pipefail

VERSION=${1:?usage: extract-schema.sh <version> [http_base] [database]}
HTTP_BASE=${2:-http://localhost:7474}
DATABASE=${3:-graph.db}

OUT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/schemas
OUT_FILE="${OUT_DIR}/reactome-${VERSION}.json"
mkdir -p "${OUT_DIR}"

TX_URL="${HTTP_BASE}/db/${DATABASE}/tx/commit"

# Run a Cypher statement over the HTTP transaction endpoint and return
# the rows as an array of column-keyed objects (e.g. [{name, versions}, …])
# rather than raw row tuples — much easier to consume downstream.
run_cypher() {
  local cypher="$1"
  local optional="${2:-false}"
  local body
  body=$(jq -n --arg q "$cypher" '{statements:[{statement:$q}]}')
  local response_file="$TMP_DIR/_response.json"
  curl -sS -H "Content-Type: application/json" -X POST -d "$body" "$TX_URL" > "$response_file"
  local err_count
  err_count=$(jq '.errors | length' < "$response_file")
  if [[ "$err_count" != "0" ]]; then
    if [[ "$optional" == "true" ]]; then
      echo "[]"
      return 0
    fi
    echo "cypher failed: $cypher" >&2
    jq '.errors' < "$response_file" >&2
    exit 1
  fi
  jq '
    .results[0] as $r
    | [ $r.data[]
      | [ [ $r.columns, .row ] | transpose[] | {(.[0]): .[1]} ]
      | add
    ]
  ' < "$response_file"
}

# Stage each query result to a temp file — apoc.meta.schema() can easily
# exceed the shell's single-argument size limit (MAX_ARG_STRLEN ~128 KB on
# Linux), so we cannot pass it via --argjson.
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

echo "extracting schema for ${VERSION} from ${HTTP_BASE} (${DATABASE})…" >&2

run_cypher 'CALL apoc.meta.schema() YIELD value RETURN value' > "$TMP_DIR/schema.json"
run_cypher 'CALL apoc.meta.stats() YIELD labels, relTypes, relTypesCount, nodeCount, relCount RETURN labels, relTypes, relTypesCount, nodeCount, relCount' > "$TMP_DIR/stats.json"
run_cypher 'CALL apoc.meta.nodeTypeProperties() YIELD nodeType, nodeLabels, propertyName, propertyTypes, mandatory RETURN nodeType, nodeLabels, propertyName, propertyTypes, mandatory' > "$TMP_DIR/nodeTypeProperties.json"
run_cypher 'CALL apoc.meta.relTypeProperties() YIELD relType, sourceNodeLabels, targetNodeLabels, propertyName, propertyTypes, mandatory RETURN relType, sourceNodeLabels, targetNodeLabels, propertyName, propertyTypes, mandatory' true > "$TMP_DIR/relTypeProperties.json"
run_cypher 'CALL db.indexes() YIELD name, state, type, entityType, labelsOrTypes, properties RETURN name, state, type, entityType, labelsOrTypes, properties' true > "$TMP_DIR/indexes.json"
run_cypher 'CALL db.constraints() YIELD name, description RETURN name, description' true > "$TMP_DIR/constraints.json"
run_cypher 'CALL dbms.components() YIELD name, versions, edition RETURN name, versions, edition' > "$TMP_DIR/dbComponents.json"

GENERATED_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# --slurpfile wraps the file contents in an array; unwrap with .[0].
jq -n \
  --arg reactomeVersion "$VERSION" \
  --arg generatedAt "$GENERATED_AT" \
  --slurpfile dbComponents "$TMP_DIR/dbComponents.json" \
  --slurpfile stats "$TMP_DIR/stats.json" \
  --slurpfile schema "$TMP_DIR/schema.json" \
  --slurpfile nodeTypeProperties "$TMP_DIR/nodeTypeProperties.json" \
  --slurpfile relTypeProperties "$TMP_DIR/relTypeProperties.json" \
  --slurpfile indexes "$TMP_DIR/indexes.json" \
  --slurpfile constraints "$TMP_DIR/constraints.json" \
  '{
    reactomeVersion: $reactomeVersion,
    generatedAt: $generatedAt,
    # dbComponents comes back as [{name, versions, edition}]; keep as array.
    dbComponents: $dbComponents[0],
    # apoc.meta.stats returns a single row with fields laid flat; unwrap.
    stats: ($stats[0][0] // {}),
    # apoc.meta.schema returns a single row with one column `value`; unwrap to just the value.
    schema: ($schema[0][0].value // {}),
    nodeTypeProperties: $nodeTypeProperties[0],
    relTypeProperties: $relTypeProperties[0],
    indexes: $indexes[0],
    constraints: $constraints[0]
  }' > "${OUT_FILE}"

BYTES=$(wc -c < "${OUT_FILE}")
echo "wrote ${OUT_FILE} (${BYTES} bytes)" >&2
