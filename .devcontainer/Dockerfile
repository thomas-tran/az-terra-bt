FROM ubuntu:focal
ENV DEBIAN_FRONTEND noninteractive
ENV TF_VERSION 1.3.6
ENV PACKER_VERSION 1.8.5
ENV GO_VERSION 1.19.4
ENV POWERSHELL_VERSION 7.3.0
ENV pip_packages "ansible cryptography pywinrm kerberos requests_kerberos passlib msrest PyVmomi pymssql"
 
# Install dev tools
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        apt-transport-https \
        gcc \
        ca-certificates \
        curl \
        git \
        gnupg \
        jq \
        krb5-user \
        krb5-config \
        libffi-dev \
        libkrb5-dev \
        libssl-dev \
        lsb-release \
        openssh-client \
        python3-dev \
        python3-gssapi \
        python3-pip \
        python3-netaddr \
        python3-jmespath \
        python3-setuptools \
        python3-wheel \
        python3-pymssql \
        sshpass \
        unzip \
        iputils-ping \
    && rm -rf /var/lib/apt/lists/* \
    && rm -Rf /usr/share/doc && rm -Rf /usr/share/man \
    && apt-get clean
 
RUN pip install --upgrade pip \
    && pip install $pip_packages \
    && pip install ansible[azure] \
    && ansible-galaxy collection install azure.azcollection community.general \
    && pip install -r ~/.ansible/collections/ansible_collections/azure/azcollection/requirements-azure.txt
 
# Install terraform, packer, tflint, terragrunt, tfsec
RUN curl -O https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip \
    && unzip terraform_${TF_VERSION}_linux_amd64.zip -d /usr/bin \
    && rm -f terraform_${TF_VERSION}_linux_amd64.zip \
    && chmod +x /usr/bin/terraform \
    && curl -sSL https://github.com/terraform-linters/tflint/releases/latest/download/tflint_linux_amd64.zip -o tflint_linux_amd64.zip \
    && unzip tflint_linux_amd64.zip \
    && rm tflint_linux_amd64.zip \
    && curl -sSL https://github.com/gruntwork-io/terragrunt/releases/latest/download/terragrunt_linux_amd64 -o terragrunt \
    && chmod u+x terragrunt \
    && curl -O https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip \
    && unzip packer_${PACKER_VERSION}_linux_amd64.zip -d /usr/bin \
    && rm -f packer_${PACKER_VERSION}_linux_amd64.zip \
    && chmod +x /usr/bin/packer \
    && curl -s https://raw.githubusercontent.com/aquasecurity/tfsec/master/scripts/install_linux.sh | bash

# Install Powershell
RUN curl -L -o /tmp/powershell.tar.gz https://github.com/PowerShell/PowerShell/releases/download/v7.3.0/powershell-${POWERSHELL_VERSION}-linux-x64.tar.gz \
    && mkdir -p /opt/microsoft/powershell/7 \
    && tar zxf /tmp/powershell.tar.gz -C /opt/microsoft/powershell/7 \
    && chmod +x /opt/microsoft/powershell/7/pwsh \
    && ln -s /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash
 
# Install Azure Devops Extension
RUN az extension add --name azure-devops

CMD    ["/bin/bash"]