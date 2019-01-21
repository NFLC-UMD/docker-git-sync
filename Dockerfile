FROM alpine:latest

# Install runtime dependencies
RUN apk update && apk upgrade
RUN apk add --no-cache bash gawk sed grep bc coreutils git openssh-client apk-cron

# Install scripts
COPY sync.sh entrypoint.sh /usr/local/bin/

VOLUME /root/.ssh
VOLUME /sync-dir

# Run the command on container startup
ENTRYPOINT ["entrypoint.sh"]
