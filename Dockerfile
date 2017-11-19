# to deploy to Clever Cloud
FROM azul/zulu-openjdk-alpine:8

#ENV LANG=C.UTF-8
ENV LANG en_US.UTF-8  
ENV LANGUAGE en_US:en  
ENV LC_ALL en_US.UTF-8

RUN apk add --no-cache

# Set the locale


ADD . /
WORKDIR /
EXPOSE 8080

CMD ./golo-dist/bin/golo golo --classpath jars/*.jar --files imports/*.golo main.golo
