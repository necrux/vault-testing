FROM alpine

RUN apk update
RUN apk add curl
RUN apk add jq
