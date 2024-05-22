#!/bin/bash
# simple script to take 'key: value' pairs and convert to a simple JSON string
#
# such that a series of values from the pipeline like the following:
# value1: abc
# value2: def
# value3: ghi
#
# becomes: 
# {"value1":"abc","value2":"def","value3":"ghi"}
#
# use flag -p to output as pretty JSON. needs a serious refactor as there's two duplicate methods for constructing the JSON and much can probably be consolidated down whether pretty or not.

while getopts "p" opt; do
  case $opt in
    p)
      pretty=true
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

if [ "${pretty}" == true ]; then
  # Read input from the pipeline
  input=$(cat)

  # Initialize an empty JSON object with an opening brace and a newline
  json="{\n"

  # Initialize a flag to track the first entry
  first_entry=true

  # Process each line of the input
  while IFS= read -r line; do
    # Split the line into key and value based on the colon
    key=$(echo "$line" | cut -d':' -f1 | xargs)
    value=$(echo "$line" | cut -d':' -f2- | xargs)
    
    # Escape double quotes in value
    value=$(echo "$value" | sed 's/"/\\"/g')
    
    # Add a comma before each new entry except the first one
    if [ "$first_entry" = false ]; then
      json="$json,\n"
    fi
    first_entry=false
    
    # Add the key-value pair to the JSON object with indentation
    json="$json  \"$key\": \"$value\""
  done <<< "$input"

  # Close the JSON object with a newline and a closing brace
  json="$json\n}"

  # Output the pretty-printed JSON object
  echo -e "$json"
else

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
fi