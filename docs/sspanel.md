# Trojan for SSPanel

### Requirements
- A domain for Trojan node to serve TLS certs
- Dev branch code of SSPanel-v3 which supports Trojan

### Install

```shell
(yum install curl 2> /dev/null || apt install curl 2> /dev/null) \
  && curl -L -s https://raw.githubusercontent.com/ColetteContreras/trojan-poseidon/master/sspanel-install-release.sh \
  | WEB_API="https://your.sspanel.domain" \
    NODE_ID=YOUR_NODE_ID \
    MU_KEY=MU_KEY \
    NODE_HOST=HOST_FOR_CURRENT_NODE \
    LICENSE=YOUR_LICENSE \
  bash
```

### Config

```shell
vim /root/trojanp/Poseidonfile
```

### Start

```shell
systemctl start trojanp
```

### Stop

```shell
systemctl stop trojanp
```

### Status

```shell
systemctl status trojanp
```

### Logs

```shell
journalctl -x -n 300 --no-pager -u trojanp
```

### Update

```shell
curl -L -s https://raw.githubusercontent.com/ColetteContreras/trojan-poseidon/master/sspanel-install-release.sh | bash
```

### Uninstall

Configs and logs **are preserved**

```shell
curl -L -s https://bit.ly/2Jl9bs7 | bash
```

