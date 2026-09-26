#!/bin/bash
set -euo pipefail
version=0.9.1
case "${1:-$(uname -m)}" in
    amd64|x86_64)
        arch=x86_64
        checksum=2a02fed16beb651ef006e1d43f048f652ca4dc58ad053cd2d44450563d5c54b7
        ;;
    aarch64|arm64)
        arch=aarch64
        checksum=f4ccf4de745f2cb9a39a983e9ba3703dad50ec2a58dea83026ceab721bbd8d9e
        ;;
    *) echo "Unsupported Herdr architecture: $1" >&2; exit 1 ;;
esac
curl --fail --location --retry 3 "https://github.com/herdrdev/herdr/releases/download/v${version}/herdr-linux-${arch}" -o /usr/local/bin/herdr
printf '%s  %s\n' "$checksum" /usr/local/bin/herdr | sha256sum -c -
chmod 755 /usr/local/bin/herdr
