FROM alpine:latest AS alpine

FROM n8nio/n8n:latest

COPY --from=alpine /sbin/apk /sbin/apk
COPY --from=alpine /usr/lib/libapk.so* /usr/lib/

USER root
RUN apk add --no-cache poppler-utils imagemagick
USER node

USER node

RUN mkdir -p /home/node/.n8n/custom && \
  cd /home/node/.n8n/custom && \
  npm install n8n-nodes-telegram-polling
