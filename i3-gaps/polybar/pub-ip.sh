#! /bin/bash

IP=$(dig +short clovel.servebeer.com)


if pgrep -x openvpn > /dev/null; then
    echo VPN: $IP
else
    echo $IP
fi
