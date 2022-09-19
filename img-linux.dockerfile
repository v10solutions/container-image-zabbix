#
# Container Image Zabbix
#

ARG HTTPD_IMG

FROM ${HTTPD_IMG}

ARG PROJ_NAME
ARG PROJ_VERSION
ARG PROJ_BUILD_NUM
ARG PROJ_BUILD_DATE
ARG PROJ_REPO

LABEL org.opencontainers.image.authors="V10 Solutions"
LABEL org.opencontainers.image.title="${PROJ_NAME}"
LABEL org.opencontainers.image.version="${PROJ_VERSION}"
LABEL org.opencontainers.image.revision="${PROJ_BUILD_NUM}"
LABEL org.opencontainers.image.created="${PROJ_BUILD_DATE}"
LABEL org.opencontainers.image.description="Container image for Zabbix"
LABEL org.opencontainers.image.source="${PROJ_REPO}"

ENV LD_LIBRARY_PATH "${LD_LIBRARY_PATH}:/usr/local/lib/zabbix"

RUN apk add --no-cache \
	"ca-certificates" \
	"curl" \
	"curl-dev" \
	"openjdk8" \
	"pcre2-dev" \
	"openssl-dev" \
	"libssh2-dev" \
	"libxml2-dev" \
	"net-snmp-dev" \
	"libevent-dev" \
	"openldap-dev" \
	"openipmi-dev" \
	"unixodbc-dev" \
	"libmodbus-dev" \
	"postgresql-dev" \
	"php81-gd" \
	"php81-xml" \
	"php81-xmlreader" \
	"php81-xmlwriter" \
	"php81-ldap" \
	"php81-ctype" \
	"php81-pgsql" \
	"php81-common" \
	"php81-bcmath" \
	"php81-gettext" \
	"php81-openssl" \
	"php81-session" \
	"php81-sockets" \
	"php81-mbstring"

RUN apk add --no-cache -t "build-deps" \
	"make" \
	"patch" \
	"linux-headers" \
	"gcc" \
	"g++" \
	"go" \
	"pkgconf" \
	"php81-apache2"

RUN groupadd -r -g "481" "zabbix" \
	&& useradd \
		-r \
		-m \
		-s "$(command -v "nologin")" \
		-g "zabbix" \
		-c "Zabbix" \
		-u "481" \
		"zabbix"

WORKDIR "/tmp"

COPY "patches" "patches"

RUN PROJ_VERSION_PARTS=(${PROJ_VERSION//\./ }) \
	&& curl -L -f -o "zabbix.tar.gz" "https://cdn.zabbix.com/zabbix/sources/stable/${PROJ_VERSION_PARTS[0]}.${PROJ_VERSION_PARTS[1]}/zabbix-${PROJ_VERSION}.tar.gz" \
	&& mkdir "zabbix" \
	&& tar -x -f "zabbix.tar.gz" -C "zabbix" --strip-components "1" \
	&& pushd "zabbix" \
	&& find "../patches" \
		-mindepth "1" \
		-type "f" \
		-iname "*.patch" \
		-exec bash --noprofile --norc -c "patch -p \"1\" < \"{}\"" ";" \
	&& ./configure \
		--prefix="/usr/local" \
		--libdir="/usr/local/lib/zabbix" \
		--libexecdir="/usr/local/libexec/zabbix" \
		--sysconfdir="/usr/local/etc/zabbix" \
		--datarootdir="/usr/local/share" \
		--sharedstatedir="/usr/local/com/zabbix" \
		--runstatedir="/usr/local/var/run/zabbix" \
		--with-zlib \
		--with-ssh2 \
		--with-ldap \
		--with-iconv \
		--with-libxml2 \
		--with-libcurl \
		--with-openssl \
		--with-net-snmp \
		--with-libevent \
		--with-libpcre2 \
		--with-openipmi \
		--with-unixodbc \
		--with-libmodbus \
		--with-libpthread \
		--with-postgresql \
		--enable-ipv6 \
		--enable-proxy \
		--enable-java \
		--enable-agent \
		--enable-agent2 \
		--enable-server \
		--enable-webservice \
	&& mv "ui/"* "/usr/local/var/lib/httpd/" \
	&& make \
	&& make "install" \
	&& ldconfig "${LD_LIBRARY_PATH}" \
	&& popd \
	&& rm -r -f "zabbix" \
	&& rm "zabbix.tar.gz" \
	&& rm -r -f "patches"

WORKDIR "/usr/local"

RUN cp "/usr/lib/apache2/mod_php"*".so" "libexec/httpd/mod_php.so"

RUN mkdir -p "etc/zabbix" "lib/zabbix" "libexec/zabbix" "share/zabbix" \
	&& folders=("com/zabbix" "var/run/zabbix") \
	&& for folder in "${folders[@]}"; do \
		mkdir -p "${folder}" \
		&& chmod "700" "${folder}" \
		&& chown -R "481":"481" "${folder}"; \
	done

WORKDIR "/tmp"

RUN mkdir "zabbix" \
	&& chmod "700" "zabbix" \
	&& chown "481":"481" "zabbix"

WORKDIR "/"

RUN apk del "build-deps"
