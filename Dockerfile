FROM alpine:3.21

RUN apk add --no-cache \
    bash \
    curl \
    python3 \
    tzdata

WORKDIR /opt/agent
COPY agent/run.sh agent/news_slack.py ./
RUN chmod +x run.sh news_slack.py

COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV NANOVM_ENV_FILE=/etc/nanovm/agent.env

ENTRYPOINT ["/entrypoint.sh"]
CMD ["sleep", "infinity"]
