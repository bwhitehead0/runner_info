#!/bin/bash

# Read key-value pairs from pipeline
while IFS=':' read -r key value; do
  # Remove leading/trailing whitespace from key and value
  key=$(echo "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

  # Add key-value pair to JSON object
  json+="\"$key\":\"$value\","
done

# Remove trailing comma from JSON object
json="${json%,}"

# Print the JSON object
echo "{$json}"