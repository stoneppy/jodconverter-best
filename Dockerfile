ARG BASE_VERSION=26.2.1

# ── Stage 1: build jodconverter-samples REST app ──────────────────────────────
FROM bellsoft/liberica-openjdk-debian:21 AS builder

RUN apt-get update \
  && apt-get install -y git \
  && git clone https://github.com/jodconverter/jodconverter-samples /src \
  && chmod +x /src/gradlew

WORKDIR /src

# 单独一层下载 gradle，每次构建都会重新执行
RUN ./gradlew --no-daemon --version

# 构建，跳过测试
RUN ./gradlew --no-daemon -x test :samples:spring-boot-rest:build

# ── Stage 2: runtime image based on our LibreOffice base ──────────────────────
ARG BASE_VERSION=26.2.1
FROM libreoffice:${BASE_VERSION}

ENV JAR_FILE_NAME=app.war \
    JAR_FILE_BASEDIR=/opt/app \
    LOG_BASE_DIR=/var/log \
    NONPRIVUSER=jodconverter \
    NONPRIVGROUP=jodconverter \
    JODCONVERTER_LOCAL_OFFICE_HOME=/opt/libreoffice26.2

# Install Java 21 and gosu
RUN dnf install -y java-21-openjdk-headless \
  && dnf clean all \
  && curl -fsSL "https://github.com/tianon/gosu/releases/download/1.17/gosu-amd64" \
       -o /usr/local/bin/gosu \
  && chmod +x /usr/local/bin/gosu

ENV JAVA_HOME=/usr/lib/jvm/jre-21
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# user/group already exists in base image, just create app dirs
RUN groupadd -f $NONPRIVGROUP \
  && useradd -m -g $NONPRIVGROUP $NONPRIVUSER 2>/dev/null || true \
  && mkdir -p ${JAR_FILE_BASEDIR} /etc/app /tmp/.jodconverter \
  && touch ${LOG_BASE_DIR}/app.log ${LOG_BASE_DIR}/app.err \
  && chown -R $NONPRIVUSER:$NONPRIVGROUP \
       ${LOG_BASE_DIR}/app.log \
       ${LOG_BASE_DIR}/app.err \
       ${JAR_FILE_BASEDIR} \
       /tmp/.jodconverter \
  && chmod 1777 /tmp

COPY --from=builder /src/samples/spring-boot-rest/build/libs/spring-boot-rest.war \
     ${JAR_FILE_BASEDIR}/${JAR_FILE_NAME}

COPY bin/docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

EXPOSE 8080

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["--spring.config.additional-location=optional:/etc/app/"]
