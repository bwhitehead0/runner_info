# Runner_Info

This action returns diagnostic information about your self-hosted ARC or EC2 instance runner.

## Examples

### Return basic diagnostic information

```yaml
on:
  push:

name: "Run ShellCheck"
permissions:
  contents: read

jobs:
  shellcheck:
    name: Shellcheck
    runs-on: [ my-private-runner ]
    steps:
      - uses: actions/checkout@v3
      - name: Gather runner diagnostic info
        uses: bwhitehead0/runner_info@v1
        with:
          detail-level: short # optional, full or short, default short
      - name: Run ShellCheck
        uses: bwhitehead0/action-shellcheck@master
```

Returns:
```
OS: Amazon Linux 2023
OS Version: 2023.3.20240219-0
Uptime: 116:02:48:08
Runner Version: 2.304.0
accountId: 123412341234
architecture: arm64
instanceId: i-123xy54321abcd0z1
instanceType: m6g.xlarge
privateIp: 10.10.10.10
region: us-east-1
```
### Return extended diagnostic information

```yaml
...
      - name: Gather runner diagnostic info
        uses: bwhitehead0/runner_info@v1
        with:
          detail-level: full # optional, full or short, default short
...
```

Returns (EC2 runner):
```
Action Version: 1.3.0
OS: Amazon Linux 2023.9.20251027
OS Version: 2023.9.20251027-0
OS Type: Host
Uptime: 305:20:26:48
Runner Date: 2026-09-02 13:38:28.153554186
Kernel Version: 6.1.156-177.286.amzn2023.x86_64
OS Hostname: runner01
Runner User: gha-runner
Runner Path: /home/gha-runner/actions-runner/
Runner Disk Used: 54%
Root Disk Used: 54%
CPU Count: 4
Memory: 32.0 GB
Free Memory: 
Runner Version: 2.330.0
Account ID: 123412341234
Architecture: x86_64
Instance ID: i-123xy54321abcd0z1
Instance Type: m1.xlarge
Private IP: 10.10.10.10
Region: us-east-1

```

Returns (ARC runner):
```
Action Version: 1.3.0
OS: Ubuntu 24.04.4 LTS
OS Version: 24.04
OS Type: Container
Uptime: 5:02:46:53
Runner Date: 2026-09-01 17:12:31.573023863
Kernel Version: 6.8.0-1029-aws
OS Hostname: arc-xscss-runner-n4qzl
Runner User: runner
Runner Path: /home/runner/
Runner Disk Used: 33%
Root Disk Used: 33%
CPU Count: 12
Memory: 32.0 GB
Free Memory: 31.9 GB
Runner Version: 2.337.0
Account ID: 123412341234
Architecture: x86_64
Instance ID: i-123xy54321abcd0z1
Instance Type: c6a.16xlarge
Private IP: 10.10.10.10
Region: us-east-1
```

## Notes

The action attempts to determine if the runner is an ARC container or a standalone host, and attempts to gather CPU and memory information appropriately.

> ⚠️ Note: `Instance Type` returns the underlying EKS node instance type when run on an ARC runner.

> ⚠️ Note: `Uptime` returns the underlying EKS node uptime when run on an ARC runner.

> 🛑 Note: See issue #21, `Free Memory` is not calculated for standalone runners (`v1.3.0`).

## Roadmap

* Capture runner stats for duration of Actions job execution and output during 'Post' cleanup step.
* Return common build tool and language versions (go, node, maven, java, python, gcc, etc)
* Return other tool versions, which might be used commonly in CI/CD workflows (gitleaks, shellcheck, jq, curl, aws cli, ansible, terraform, etc)
* Simple JSON output option
* Save as job artifact to github
* User input for cloud provider, return comparable instance details across providers.
* Accept list of tag key names as input to retrieve from instance metadata endpoint, if available (see [this link](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Using_Tags.html#allow-access-to-tags-in-IMDS) for more info)