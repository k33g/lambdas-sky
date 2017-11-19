# to deploy to Clever Cloud
FROM azul/zulu-openjdk-alpine:8

RUN apk add --no-cache

# Set the locale
RUN locale-gen en_US.UTF-8  
ENV LANG en_US.UTF-8  
ENV LANGUAGE en_US:en  
ENV LC_ALL en_US.UTF-8

ADD . /
WORKDIR /
EXPOSE 8080

CMD ./golo-dist/bin/golo golo --classpath jars/*.jar --files imports/*.golo main.golo
