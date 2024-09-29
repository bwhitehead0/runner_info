#!/bin/bash

echo "\$GITHUB_WORKSPACE: $GITHUB_WORKSPACE"
folder=${GITHUB_WORKSPACE%work_*}
echo "from GITHUB_WORKSPACE: $folder"

# action version
VERSION="1.1.0"
# Get OS name
OS_NAME=$(grep "PRETTY_NAME=" /etc/os-release | cut -d'"' -f2)
# https://unix.stackexchange.com/a/34033 - get uptime from /proc/uptime in human readable format
UPTIME=$(awk '{printf("%d:%02d:%02d:%02d\n",($1/60/60/24),($1/60/60%24),($1/60%60),($1%60))}' /proc/uptime)

# Get OS Version
if [[ $OS_NAME == *"Amazon"* ]]; then
  # Amazon Linux
  OS_VERSION=$(rpm -q system-release | sed -n 's/system-release-\(.*\)\.amzn2023.noarch/\1/p')
elif [[ $OS_NAME == *"CentOS"* ]]; then
  # CentOS
  OS_VERSION="$(rpm -q --qf "%{VERSION}" "$(rpm -q --whatprovides redhat-release)")"
elif [[ $OS_NAME == *"Red Hat"* ]]; then
  # Red Hat
  OS_VERSION="$(rpm -q --qf "%{VERSION}" "$(rpm -q --whatprovides redhat-release)")"
elif [[ $OS_NAME == *"Ubuntu"* ]]; then
  # Ubuntu
  OS_VERSION=$(lsb_release -r | awk '{print $2}')
elif [[ $OS_NAME == *"Debian"* ]]; then
  # Debian
  OS_VERSION=$(lsb_release -r | awk '{print $2}')
# Might need to add some more options here if there are any common self-hosted runner OSes out there.
else
  OS_VERSION=""
fi

echo "Action Version: ${VERSION}"
echo "OS: ${OS_NAME}"
echo "OS Version: ${OS_VERSION}"
echo "Uptime: ${UPTIME}"

# if runner service is running then we can determine installation path and get additional info
if pgrep "runsvc.sh" >/dev/null; then
  # runner is running and we can easily find the disk it's installed on
  # ignore shellcheck warning as pidof isn't going to get us what we need here
  # shellcheck disable=SC2009
  RUNNER_PATH="$(dirname "$(ps aux | grep -w "[r]unsvc.sh" | awk '{print $12}')")"
else
  # runner is not running, so we'll just default to blank
  RUNNER_PATH=""
fi


# if action variable INPUT_DETAIL_LEVEL is set, gather additional info
# ignore shellcheck warnings about the variable not being defined, as it's set by the runner execution
# shellcheck disable=SC2154
if [[ ${INPUT_DETAIL_LEVEL} == "full" ]]; then
  echo "Kernel Version: $(uname -r)"
  echo "OS Hostname: $(hostname)"
  echo "Runner User: $(whoami)"
  if [ -z "${RUNNER_PATH}" ]; then
    DISK_USED=""
  else
    DISK_USED=$(df -hP "${RUNNER_PATH}" | awk 'NR==2 {print $5}')
  fi
  echo "Runner Path: ${RUNNER_PATH}"
  echo "Runner Disk Used: ${DISK_USED}"
  echo "Root Disk Used: $(df -hP / | awk 'NR==2 {print $5}')"
fi

if [ -z "${RUNNER_PATH}" ]; then
    # get runner version
    RUNNER_VERSION=""
  else
    # need to cd to the runner path to get the version to avoid error output about missing libraries etc, or just use "" in case of other issues getting version
    RUNNER_VERSION=$( (cd "${RUNNER_PATH}" && ./config.sh --version 2>/dev/null) || echo "" )
fi

echo "Runner Version: ${RUNNER_VERSION}"

TOKEN=$(curl -m 1 -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
# could use JQ to parse the JSON output but some older instances won't have it installed
# sed to remove quotes and commas and leading whitespace etc, second sed to format the output
curl -s -m 1 -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/dynamic/instance-identity/document | grep 'accountId\|architecture\|instanceId\|instanceType\|privateIp\|region' | sed 's/\"//g; s/\,//g; s/^[ \t]*//; s/ : /: /' | sed 's/region/Region/; s/accountId/Account ID/; s/architecture/Architecture/; s/instanceId/Instance ID/; s/instanceType/Instance Type/; s/privateIp/Private IP/'