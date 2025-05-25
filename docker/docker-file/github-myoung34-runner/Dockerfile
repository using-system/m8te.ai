FROM myoung34/github-runner:latest

ENV KUBECTL_VERSION=v1.33.1
ENV KUBELOGIN_VERSION=latest
ENV NODE_VERSION=20.14.0

RUN apt-get update && \
    apt-get install -y \
    ca-certificates \
    curl \
    apt-transport-https \
    lsb-release \
    gnupg \
    unzip \
    xz-utils && \
    \
    # Azure CLI
    curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg && \
    install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/ && \
    echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" > /etc/apt/sources.list.d/azure-cli.list && \
    apt-get update && \
    apt-get install -y azure-cli && \
    rm -f microsoft.gpg && \
    \
    # kubectl
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    rm kubectl && \
    \
    # kubelogin
    curl -L -o /tmp/kubelogin.zip "https://github.com/Azure/kubelogin/releases/${KUBELOGIN_VERSION}/download/kubelogin-linux-amd64.zip" && \
    unzip -q /tmp/kubelogin.zip -d /tmp/kubelogin && \
    install -o root -g root -m 0755 /tmp/kubelogin/bin/linux_amd64/kubelogin /usr/local/bin/kubelogin && \
    rm -rf /tmp/kubelogin /tmp/kubelogin.zip  && \
    \
    # Node.js 20
    curl -fsSL https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz -o node.tar.xz && \
    mkdir -p /usr/local/lib/nodejs && \
    tar -xJf node.tar.xz -C /usr/local/lib/nodejs && \
    rm node.tar.xz && \
    ln -s /usr/local/lib/nodejs/node-v${NODE_VERSION}-linux-x64/bin/node /usr/local/bin/node && \
    ln -s /usr/local/lib/nodejs/node-v${NODE_VERSION}-linux-x64/bin/npm /usr/local/bin/npm && \
    ln -s /usr/local/lib/nodejs/node-v${NODE_VERSION}-linux-x64/bin/npx /usr/local/bin/npx && \
    \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*