FROM rockylinux:9

ARG LIBREOFFICE_VERSION=26.2.1

ENV SAL_USE_VCLPLUGIN=svp \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

RUN dnf install -y \
      tar \
      fontconfig \
      cairo \
      cups-libs \
      libSM \
      libXinerama \
      libXrender \
      libXext \
      libX11 \
      libX11-xcb \
      libxcb \
      libXau \
      libXdmcp \
      nss \
      nss-util \
      nspr \
      dbus-libs \
      dbus-glib \
      glib2 \
      java-21-openjdk-headless \
      procps-ng \
      glibc-langpack-en \
  && dnf clean all

ENV JAVA_HOME=/usr/lib/jvm/jre-21
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# Copy local package if exists (use a placeholder to avoid COPY failure)
COPY package/ /tmp/packages/

# Install LibreOffice: use local package if available, otherwise download
RUN LOCAL_PKG=$(find /tmp/packages -name "LibreOffice_${LIBREOFFICE_VERSION}_Linux_x86-64_rpm.tar.gz" 2>/dev/null | head -1) \
  && if [ -n "$LOCAL_PKG" ]; then \
       echo "Using local package: $LOCAL_PKG" \
       && cp "$LOCAL_PKG" /tmp/lo.tar.gz; \
     else \
       echo "Downloading LibreOffice ${LIBREOFFICE_VERSION} from official site..." \
       && curl -fsSL "https://download.documentfoundation.org/libreoffice/stable/${LIBREOFFICE_VERSION}/rpm/x86_64/LibreOffice_${LIBREOFFICE_VERSION}_Linux_x86-64_rpm.tar.gz" \
            -o /tmp/lo.tar.gz; \
     fi \
  && tar -xzf /tmp/lo.tar.gz -C /tmp \
  && dnf install -y /tmp/LibreOffice_*/RPMS/*.rpm \
  && rm -rf /tmp/lo.tar.gz /tmp/LibreOffice_* /tmp/packages

RUN LO_BIN=$(find /opt -name "soffice" -type f 2>/dev/null | head -1) \
  && LO_DIR=$(dirname "$LO_BIN") \
  && ln -sf "$LO_BIN" /usr/local/bin/soffice \
  && ln -sf "$LO_BIN" /usr/local/bin/libreoffice

RUN soffice --headless --version

CMD ["soffice", "--headless"]
