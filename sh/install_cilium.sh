CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)

curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-arm64.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-arm64.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-arm64.tar.gz /usr/local/bin
rm cilium-linux-arm64.tar.gz{,.sha256sum}

cilium install --version 1.14.6
