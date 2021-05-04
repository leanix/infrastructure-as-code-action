FROM leanix/terragrunt:latest

RUN apt update && apt install -y ca-certificates jq && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]