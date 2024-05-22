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
# use flag -p to output as pretty JSON, and the above example would become:
# {
#   "value1": "abc",
#   "value2": "def",
#   "value3": "ghi"
# }

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

newline=$'\n'
first_entry=true

# Read key-value pairs from pipeline
while IFS=':' read -r key value; do
  # Remove leading/trailing whitespace from key and value, and escape double quotes in value
  key=$(echo "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//;s/\"/\\\"/g')

  if [ "${pretty}" == true ]; then
    # Add a comma before each new entry except the first one
    if [ "$first_entry" = false ]; then
      json="$json,${newline}"
    fi
    first_entry=false

    # Add the key-value pair to the JSON object with indentation
    json="$json  \"$key\": \"$value\""
  else
    # Add key-value pair to JSON object
    json+="\"$key\":\"$value\","
  fi
done

# build either pretty or non-pretty JSON and remove trailing comma
if [ "${pretty}" == true ]; then
  json="{${newline}${json%,}${newline}}"
else
  json="{${json%,}}"
fi

# print the JSON object
echo "$json"