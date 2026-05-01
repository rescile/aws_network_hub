#!/usr/bin/env bash

# Configuration
SOURCE_NAME="Boto3/Botocore Endpoints"
URL="https://raw.githubusercontent.com/boto/botocore/develop/botocore/data/endpoints.json"
FILE="data/input/aws_endpoints_raw.json"
ETAG_FILE="data/generators/aws_region_service.etag"
MOD_DATE_FILE="data/generators/aws_region_service.last_mod"
OUTPUT_FILE="data/input/aws_region_service.json"

# Ensure directories exist
mkdir -p input generators

RESPONSE_HEADERS=$(curl -s -I \
    --etag-compare "$ETAG_FILE" \
    --etag-save "$ETAG_FILE" \
    "$URL")

STATUS=$(echo "$RESPONSE_HEADERS" | grep HTTP | tail -1 | awk '{print $2}')

echo "------------------------------------------"
echo "SOURCE: $SOURCE_NAME"

if [ "$STATUS" -eq 200 ]; then
    curl -s -o "$FILE" "$URL"
    NEW_DATE=$(echo "$RESPONSE_HEADERS" | grep -i "last-modified:" | cut -d' ' -f2- | tr -d '\r')
    echo "$NEW_DATE" > "$MOD_DATE_FILE"
    echo "STATUS: New version downloaded!"
elif [ "$STATUS" -eq 304 ]; then
    SAVED_DATE=$(cat "$MOD_DATE_FILE" 2>/dev/null || echo "Unknown")
    echo "STATUS: No update needed (Cached)"
    echo "LAST UPDATED: $SAVED_DATE"
else
    echo "STATUS: Error (HTTP $STATUS)"
    exit 1
fi

echo "Processing structured output..."

# This JQ logic parses the Botocore endpoints file
# It extracts the region names and the list of services for each
jq '
  .partitions[0] as $p |
  [
    $p.regions | to_entries[] | .key as $region_code | {
      region: $region_code,
      location: .value.description,
      service: [
        $p.services | to_entries[] |
        # Check if endpoints exist AND if this region is in them
        select(.value.endpoints? | has($region_code)) |
        .key
      ] | sort
    }
  ]
' "$FILE" > "$OUTPUT_FILE"

echo "------------------------------------------"
