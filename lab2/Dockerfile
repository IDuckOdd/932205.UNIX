FROM alpine:latest

RUN apk add --no-cache util-linux

WORKDIR /app

COPY manage_files.sh .

RUN chmod +x manage_files.sh

ENTRYPOINT ["/app/manage_files.sh"]
