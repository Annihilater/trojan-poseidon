#!/bin/bash

NEW_VER=v0.0.9
DOWNLOAD_LINK="https://github.com/ColetteContreras/trojan-poseidon/releases/download/${NEW_VER}/trojanp-linux-64.zip"

INSTALL_DIR=${INSTALL_DIR:-"/root"}
mkdir -p "$INSTALL_DIR" || (echo "mkdir ${INSTALL_DIR} error"; return $?)

INSTALL_DIR="${INSTALL_DIR%/}/trojanp/"

SYSTEMCTL_CMD=$(command -v systemctl 2>/dev/null)
SERVICE_CMD=$(command -v service 2>/dev/null)

CMD_INSTALL=""
CMD_UPDATE=""
SOFTWARE_UPDATED=0

####### color code ########
RED="31m"      # Error message
GREEN="32m"    # Success message
YELLOW="33m"   # Warning message
BLUE="36m"     # Info message

###############################
colorEcho(){
    COLOR=$1
    echo -e "\033[${COLOR}${@:2}\033[0m"
}


ZIPFILE="$(mktemp -d)/trojanp.zip"

# return 1: not apt, yum, or zypper
getPMT(){
    if [[ -n `command -v apt-get` ]];then
        CMD_INSTALL="apt-get -y -qq install"
        CMD_UPDATE="apt-get -qq update"
    elif [[ -n `command -v yum` ]]; then
        CMD_INSTALL="yum -y -q install"
        CMD_UPDATE="yum -q makecache"
    elif [[ -n `command -v zypper` ]]; then
        CMD_INSTALL="zypper -y install"
        CMD_UPDATE="zypper ref"
    else
        return 1
    fi
    return 0
}

installSoftware(){
    COMPONENT=$1
    if [[ -n `command -v $COMPONENT` ]]; then
        return 0
    fi

    getPMT
    if [[ $? -eq 1 ]]; then
        colorEcho ${RED} "The system package manager tool isn't APT or YUM, please install ${COMPONENT} manually."
        return 1
    fi
    if [[ $SOFTWARE_UPDATED -eq 0 ]]; then
        colorEcho ${BLUE} "Updating software repo"
        $CMD_UPDATE
        SOFTWARE_UPDATED=1
    fi

    colorEcho ${BLUE} "Installing ${COMPONENT}"
    $CMD_INSTALL $COMPONENT
    if [[ $? -ne 0 ]]; then
        colorEcho ${RED} "Failed to install ${COMPONENT}. Please install it manually."
        return 1
    fi
    return 0
}

downloadTrojanPoseidon(){
    colorEcho ${BLUE} "Downloading Trojan-Poseidon."
    curl ${PROXY} -L -H "Cache-Control: no-cache" -o ${ZIPFILE} ${DOWNLOAD_LINK}
    if [ $? != 0 ];then
        colorEcho ${RED} "Failed to download! Please check your network or try again."
        return 3
    fi
    return 0
}

extract(){
    colorEcho ${BLUE}"Extracting Trojan-Poseidon package to ${INSTALL_DIR}"
    unzip -o $1 -d ${INSTALL_DIR}
    if [[ $? -ne 0 ]]; then
        colorEcho ${RED} "Failed to extract Trojan-Poseidon."
        return 2
    fi
    return 0
}

stopTrojanPoseidon(){
    colorEcho ${BLUE} "Shutting down Trojan-Poseidon service."
    systemctl stop trojanp
    if [[ $? -ne 0 ]]; then
        colorEcho ${YELLOW} "Failed to shutdown Trojan-Poseidon service."
        return 2
    fi
    return 0
}

startTrojanPoseidon(){
    systemctl start trojanp
    if [[ $? -ne 0 ]]; then
        colorEcho ${YELLOW} "Failed to start Trojan-Poseidon service."
        return 2
    fi
    colorEcho ${GREEN} "Trojsn-Poseidon service started"
    return 0
}


installTrojanPoseidon(){
    chmod +x trojanp

    if [[ ! -f "Poseidonfile" ]]; then
        nodeId=${NODE_ID:-"NODE_ID"}
        nodeKey=${NODE_KEY:-"NODE_KEY"}
        nodeHost=${NODE_HOST:-"请替换为你的节点域名"}
        webApi=${WEB_API:-"http或https://面板地址"}
        email=${EMAIL:-"trojan@poseidon.com"}


        cat >Poseidonfile <<EOF
# See https://colettecontreras.github.io/trojan-poseidon/#/?id=poseidonfile
# to understand configs deeper

$nodeHost:443

# Uncomment below to enable local static web server
# root /var/www/html

# Mirror a website of your desire
mirror https://colettecontreras.github.io/t-rex-runner

# Change email to your own to get a tls from Let's Encrypt
# 80 port MUST be free
# format1: tls <email>
tls $email

# If you already hold your tls certifications, # you can use format2,
# which will not occupy 80 port
# format2: tls server.crt server.key

# format: vnetpanel apiHost nodeID secretKey
vnetpanel $webApi $nodeId $nodeKey
EOF
    fi

    mv trojanp.service /etc/systemd/system/
    systemctl daemon-reload

    return 0
}

disableFirewall(){
    systemctl stop firewalld 2> /dev/null
    systemctl disable firewalld 2> /dev/null
    colorEcho ${YELLOW} "Firewall disabled"
}

main(){
    colorEcho ${BLUE} "Installing Trojan-Poseidon ${NEW_VER}"
    disableFirewall || return $?

    # install deps
    installSoftware "curl" || return $?
    installSoftware "unzip" || return $?

    # download and extract
    downloadTrojanPoseidon || return $?
    extract ${ZIPFILE} || return $?
    rm -rf ${ZIPFILE}
    cd "$INSTALL_DIR"
    installTrojanPoseidon || return $?
    startTrojanPoseidon || return $?
}

main

