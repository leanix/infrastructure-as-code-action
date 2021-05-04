FROM leanixacrpublic.azurecr.io/terragrunt:latest

RUN apk update && apk add ca-certificates && rm -rf /var/cache/apk/* && update-ca-certificates

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]