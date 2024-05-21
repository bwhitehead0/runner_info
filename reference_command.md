# The reference command the GitHub Action is based on.


```bash
#!/bin/bash
# Get OS name
echo "OS: $(grep "PRETTY_NAME" /etc/os-release | cut -d'"' -f2)"
echo "OS Version: $(cat /var/log/dnf.log | grep -i "ddebug releasever:" | rev | cut -f 1 -d " " | rev | tail -n 1)"

TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
# could use JQ to parse the JSON output but some older instances won't have it installed
# sed to remove quotes and commas and leading whitespace etc
curl -s -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/dynamic/instance-identity/document | grep 'accountId\|architecture\|instanceId\|instanceType\|privateIp\|region' | sed 's/\"//g; s/\,//g; s/^[ \t]*//; s/ : /: /'
```

Returns the following info:

```
OS: Amazon Linux 2023
accountId: 123412341234
architecture: arm64
instanceId: i-123xy54321abcd0z1
instanceType: m6g.xlarge
privateIp: 10.16.20.169
region: us-east-1
```