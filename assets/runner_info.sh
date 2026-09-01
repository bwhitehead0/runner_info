#!/bin/bash

is_container() {
    # Docker creates this file
    [ -f /.dockerenv ] && return 0

    # Podman creates this file
    [ -f /run/.containerenv ] && return 0

    # Kubernetes pod
    [ -n "${KUBERNETES_SERVICE_HOST:-}" ] && return 0
    [ -d /var/run/secrets/kubernetes.io/serviceaccount ] && return 0

    # Root filesystem is overlay (Docker, containerd, k8s)
    grep -q '^[^ ]* / overlay ' /proc/1/mountinfo 2>/dev/null && return 0

    # cgroup v1/v2: known container-runtime cgroup paths
    if [ -f /proc/1/cgroup ]; then
        grep -qE '(kubepods|docker|containerd|cri-containerd|buildkit|ecs|lxc)' /proc/1/cgroup 2>/dev/null && return 0
    fi

    # systemd-detect-virt if available
    if command -v systemd-detect-virt >/dev/null 2>&1; then
        systemd-detect-virt -c >/dev/null 2>&1 && return 0
    fi

    return 1
}

get_cpu_count() {
  # cgroup v2: /sys/fs/cgroup/cpu.max
  if [ -f /sys/fs/cgroup/cpu.max ]; then
    read quota period < /sys/fs/cgroup/cpu.max
    if [ "$quota" != "max" ] && [ "$period" -gt 0 ]; then
      cpus=$(awk "BEGIN { printf \"%d\", ($quota + $period - 1) / $period }")
      echo "$cpus"
      return
    fi
  fi

  # cgroup v1: /sys/fs/cgroup/cpu/cpu.cfs_quota_us and cpu.cfs_period_us
  if [ -f /sys/fs/cgroup/cpu/cpu.cfs_quota_us ] && [ -f /sys/fs/cgroup/cpu/cpu.cfs_period_us ]; then
    quota=$(cat /sys/fs/cgroup/cpu/cpu.cfs_quota_us)
    period=$(cat /sys/fs/cgroup/cpu/cpu.cfs_period_us)
    if [ "$quota" -gt 0 ] && [ "$period" -gt 0 ]; then
      cpus=$(awk "BEGIN { printf \"%d\", ($quota + $period - 1) / $period }")
      echo "$cpus"
      return
    fi
  fi

  # Try nproc (common on Linux)
  if command -v nproc >/dev/null 2>&1; then
    nproc
    return
  fi

  # Try getconf (POSIX, works on many systems)
  if command -v getconf >/dev/null 2>&1; then
    getconf _NPROCESSORS_ONLN 2>/dev/null && return
    getconf NPROCESSORS_ONLN 2>/dev/null && return
  fi

  # Try sysctl (BSD, macOS)
  if command -v sysctl >/dev/null 2>&1; then
    sysctl -n hw.ncpu 2>/dev/null && return
  fi

  # Fallback: count 'processor' lines in /proc/cpuinfo (Linux)
  if [ -f /proc/cpuinfo ]; then
    grep -c ^processor /proc/cpuinfo
    return
  fi

  # Fallback: 1 (unknown)
  echo 1
}

get_memory_bytes() {
    # cgroup v2
    if [ -f /sys/fs/cgroup/memory.max ]; then
        val=$(cat /sys/fs/cgroup/memory.max)
        if [ "$val" != "max" ]; then
            echo "$val"
            return 0
        fi
    fi

    # cgroup v1
    if [ -f /sys/fs/cgroup/memory/memory.limit_in_bytes ]; then
        val=$(cat /sys/fs/cgroup/memory/memory.limit_in_bytes)
        # values near PAGE_COUNTER_MAX mean unlimited
        if [ "$val" -lt 9000000000000000000 ] 2>/dev/null; then
            echo "$val"
            return 0
        fi
    fi

    # Fallback: node-level memory
    awk '/^MemTotal:/ { print $2 * 1024 }' /proc/meminfo
}

# action version
VERSION="1.3.0"
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

# determine if this is a container
if is_container; then
    OS_TYPE="Container"
else
    OS_TYPE="Host"
fi

echo "Action Version: ${VERSION}"
echo "OS: ${OS_NAME}"
echo "OS Version: ${OS_VERSION}"
echo "OS Type: ${OS_TYPE}"
echo "Uptime: ${UPTIME}"
echo "Runner Date: $(date +'%Y-%m-%d %H:%M:%S.%9N' )"

RUNNER_PATH=${GITHUB_WORKSPACE%%_work*}

# if action variable INPUT_DETAIL_LEVEL is set, gather additional info
# ignore shellcheck warnings about the variable not being defined, as it's set by the runner execution
# shellcheck disable=SC2154
if [[ ${INPUT_DETAIL_LEVEL} == "full" ]]; then
  # Get memory and convert to human readable format
  MEMORY_GB=$(get_memory_bytes | awk '{ printf "%.1f GB", $1 / (1024^3) }')
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
  echo "CPU Count: $(get_cpu_count)"
  echo "Memory: ${MEMORY_GB}"
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