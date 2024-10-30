FROM alpine
RUN apk add aws-cli curl kubectl bash groff mandoc jq redis
COPY auto.sh .
COPY cluster2 cluster2
COPY cluster1 cluster1
CMD [ "/bin/bash", "-c", "bash auto.sh"]