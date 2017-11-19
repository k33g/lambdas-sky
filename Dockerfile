# to deploy to Clever Cloud
FROM azul/zulu-openjdk-alpine:8

RUN apk add --no-cache
ADD . /
WORKDIR /
EXPOSE 8080
ENV LANG en_US.UTF-8
CMD ./golo-dist/bin/golo golo --classpath jars/*.jar --files imports/*.golo main.golo
