#!/usr/bin/env bash

# Configuration
SOURCE_NAME="Boto3/Botocore Endpoints"
URL="https://raw.githubusercontent.com/boto/botocore/develop/botocore/data/endpoints.json"
# Ensure these paths are correct relative to where you RUN the script
FILE="input/aws_endpoints_raw.json"
ETAG_FILE="generators/aws_region_service.etag"
MOD_DATE_FILE="generators/aws_region_service.last_mod"
OUTPUT_FILE="input/aws_region_service.json"
HEADER_FILE="generators/aws_headers.tmp"

# --- FIX 1: Ensure the EXACT directories in your variables exist ---
mkdir -p "input" "generators"

# --- FIX 2: Clear STATUS and capture ONLY the 3-digit code ---
# Using --location in case GitHub redirects
STATUS=$(curl -s -L -I -o "$HEADER_FILE" \
    --etag-compare "$ETAG_FILE" \
    --etag-save "$ETAG_FILE" \
    -w "%{http_code}" \
    "$URL")

echo "------------------------------------------"
echo "SOURCE: $SOURCE_NAME"

# Check if STATUS is a valid 3-digit number
if [[ ! "$STATUS" =~ ^[0-9]{3}$ ]]; then
    echo "STATUS: Failed to connect or invalid response (Code: $STATUS)"
    exit 1
fi

if [ "$STATUS" -eq 200 ]; then
    curl -s -L -o "$FILE" "$URL"
    NEW_DATE=$(grep -i "last-modified:" "$HEADER_FILE" | cut -d' ' -f2- | tr -d '\r')
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

# Ensure $FILE exists before running JQ
if [ ! -f "$FILE" ]; then
    echo "Error: $FILE not found. Cannot process JQ."
    exit 1
fi

jq '
  .partitions[0] as $p |
  $p.regions | to_entries | map(
    .key as $region_code |
    {
      key: .value.description,
      value: {
        region_code: $region_code,
        services: [
          $p.services | to_entries[] |
          select(.value.endpoints? | has($region_code)) |
          .key
        ] | sort
      }
    }
  ) | from_entries
' "$FILE" > "$OUTPUT_FILE"

echo "------------------------------------------"
