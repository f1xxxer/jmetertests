# inspired by https://github.com/justb4/docker-jmeter/blob/master/Dockerfile
FROM alpine:3.12

ARG JMETER_VERSION="5.4"
ENV JMETER_HOME /opt/apache-jmeter-${JMETER_VERSION}
ENV	JMETER_BIN	${JMETER_HOME}/bin
ENV	JMETER_DOWNLOAD_URL  https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-${JMETER_VERSION}.tgz

RUN    apk update \
	&& apk upgrade \
	&& apk add bash \
	&& apk add ca-certificates \
	&& update-ca-certificates \
	&& apk add --update openjdk8-jre tzdata curl unzip bash \
	&& apk add --no-cache nss \
	&& rm -rf /var/cache/apk/* \
	&& mkdir -p /tmp/dependencies  \
	&& curl -L --silent ${JMETER_DOWNLOAD_URL} >  /tmp/dependencies/apache-jmeter-${JMETER_VERSION}.tgz  \
	&& mkdir -p /opt  \
	&& tar -xzf /tmp/dependencies/apache-jmeter-${JMETER_VERSION}.tgz -C /opt  \
	&& rm -rf /tmp/dependencies

# Set global PATH such that "jmeter" command is found
ENV PATH $PATH:$JMETER_BIN

# disable ssl for local network connections
RUN sed -i "s/#server.rmi.ssl.disable=false/server.rmi.ssl.disable=true/" $JMETER_BIN/jmeter.properties

# Entrypoint has same signature as "jmeter" command
COPY ../entrypointController.sh /

WORKDIR	${JMETER_HOME}

ENTRYPOINT ["/entrypointController.sh"]
