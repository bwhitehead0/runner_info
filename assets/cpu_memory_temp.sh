#!/bin/sh

# cgroup v2: /sys/fs/cgroup/cpu.max
if [ -f /sys/fs/cgroup/cpu.max ]; then
  read quota period < /sys/fs/cgroup/cpu.max
  if [ "$quota" != "max" ] && [ "$period" -gt 0 ]; then
    cpus=$(awk "BEGIN { printf \"%d\", ($quota + $period - 1) / $period }")
    echo "$cpus"
    exit 0
  fi
fi

# cgroup v1: /sys/fs/cgroup/cpu/cpu.cfs_quota_us and cpu.cfs_period_us
if [ -f /sys/fs/cgroup/cpu/cpu.cfs_quota_us ] && [ -f /sys/fs/cgroup/cpu/cpu.cfs_period_us ]; then
  quota=$(cat /sys/fs/cgroup/cpu/cpu.cfs_quota_us)
  period=$(cat /sys/fs/cgroup/cpu/cpu.cfs_period_us)
  if [ "$quota" -gt 0 ] && [ "$period" -gt 0 ]; then
    cpus=$(awk "BEGIN { printf \"%d\", ($quota + $period - 1) / $period }")
    echo "$cpus"
    exit 0
  fi
fi

# Try nproc (common on Linux)
if command -v nproc >/dev/null 2>&1; then
  nproc
  exit 0
fi

# Try getconf (POSIX, works on many systems)
if command -v getconf >/dev/null 2>&1; then
  getconf _NPROCESSORS_ONLN 2>/dev/null && exit 0
  getconf NPROCESSORS_ONLN 2>/dev/null && exit 0
fi

# Try sysctl (BSD, macOS)
if command -v sysctl >/dev/null 2>&1; then
  sysctl -n hw.ncpu 2>/dev/null && exit 0
fi

# Fallback: count 'processor' lines in /proc/cpuinfo (Linux)
if [ -f /proc/cpuinfo ]; then
  grep -c ^processor /proc/cpuinfo
  exit 0
fi

# Fallback: 1 (unknown)
echo 1