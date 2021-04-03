FROM debian:buster-slim

RUN apt update && apt install -y \
    openconnect \
    cron \
    cifs-utils \
    rsync

COPY sync.sh /app/sync.sh

CMD /app/sync.sh