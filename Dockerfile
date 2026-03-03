ARG BASE_VERSION=26.2.1
ARG DOCKER_USERNAME=library

# ── Stage 1: build jodconverter-samples REST app ──────────────────────────────
FROM bellsoft/liberica-openjdk-debian:21 AS builder

RUN apt-get update \
  && apt-get install -y git \
  && git clone https://github.com/jodconverter/jodconverter-samples /src \
  && chmod +x /src/gradlew

WORKDIR /src
RUN ./gradlew --no-daemon --version
RUN ./gradlew --no-daemon -x test :samples:spring-boot-rest:build

# ── Stage 2: runtime image based on our LibreOffice base ──────────────────────
FROM ${DOCKER_USERNAME}/libreoffice:${BASE_VERSION}
ARG CACHEBUST=1

ENV JAR_FILE_NAME=app.war \
    JAR_FILE_BASEDIR=/opt/app \
    LOG_BASE_DIR=/var/log \
    NONPRIVUSER=jodconverter \
    NONPRIVGROUP=jodconverter \
    JODCONVERTER_LOCAL_OFFICE_HOME=/opt/libreoffice26.2 \
    JODCONVERTER_LOCAL_OFFICE_EXECUTABLE=soffice \
    JODCONVERTER_LOCAL_PROCESS_MANAGER=org.jodconverter.local.process.UnixProcessManager \
    JAVA_HOME=/usr/lib/jvm/jre-21

ENV PATH="${JAVA_HOME}/bin:${PATH}"

RUN curl -fsSL "https://github.com/tianon/gosu/releases/download/1.17/gosu-amd64" \
       -o /usr/local/bin/gosu \
  && chmod +x /usr/local/bin/gosu

RUN groupadd -f $NONPRIVGROUP \
  && useradd -m -g $NONPRIVGROUP $NONPRIVUSER 2>/dev/null || true \
  && mkdir -p ${JAR_FILE_BASEDIR} /etc/app \
  && touch ${LOG_BASE_DIR}/app.log ${LOG_BASE_DIR}/app.err \
  && chown -R $NONPRIVUSER:$NONPRIVGROUP \
       ${LOG_BASE_DIR}/app.log \
       ${LOG_BASE_DIR}/app.err \
       ${JAR_FILE_BASEDIR}

COPY --from=builder /src/samples/spring-boot-rest/build/libs/spring-boot-rest.war \
     ${JAR_FILE_BASEDIR}/${JAR_FILE_NAME}

COPY bin/docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["--spring.config.additional-location=optional:/etc/app/"]
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["--spring.config.additional-location=optional:/etc/app/"]
