# Runner_Info

This action returns diagnostic information about your self-hosted Linux runner running on an AWS EC2 instance.

## Examples

### Return basic diagnostic information

```yaml
on:
  push:

name: "Trigger: Push action"
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
privateIp: 10.16.20.169
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

Returns:
```
OS: Amazon Linux 2023
OS Version: 2023.3.20240219-0
Uptime: 116:02:48:08
Kernel Version: 6.1.77-99.164.amzn2023.aarch64
OS Hostname: private-runner01
Runner User: runner-user
Runner Path: /home/runner-user/actions-runner
Runner Disk Used: 1%
Root Disk Used: 7%
Runner Version: 2.304.0
Account ID: 123412341234
Architecture: arm64
Instance ID: i-123xy54321abcd0z1
Instance Type: m6g.xlarge
Private Ip: 10.16.20.169
Region: us-east-1
```

## Roadmap

* Return common build tool and language versions (go, node, maven, java, python, gcc, etc)
* Return other tool versions, which might be used commonly in CI/CD workflows (gitleaks, shellcheck, jq, curl, aws cli, ansible, terraform, etc)
* Simple JSON output option
* Save as job artifact to github
* User input for cloud provider, return comparable instance details across providers.
* Accept list of tag key names as input to retrieve from instance metadata endpoint, if available (see [this link](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Using_Tags.html#allow-access-to-tags-in-IMDS) for more info)