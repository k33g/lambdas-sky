FROM azul/zulu-openjdk-alpine:8

RUN apk add --no-cache


ADD . /
WORKDIR /

EXPOSE 8080

#RUN ./build-jar.sh
CMD ./golo-dist/bin/golo golo --classpath jars/*.jar --files imports/*.golo main.golo

# docker build -t lambdas-sky .
# docker run -p 8080:8080 --name lambdas-sky-container -i -t lambdas-sky