FROM alpine:edge
MAINTAINER Hypoport 

RUN apk update && apk --no-cache add socat bash jq curl sed openssl xmlstarlet

WORKDIR /socat_server

ADD *.sh /socat_server/
ADD handlers /socat_server/handlers
ADD lib /socat_server/lib
RUN mkdir /socat_server/public_keys

EXPOSE 8080

CMD ["./run.sh"]

