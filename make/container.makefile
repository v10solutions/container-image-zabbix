#
# Container Image Zabbix
#

.PHONY: container-server-run-linux
container-server-run-linux:
	$(BIN_DOCKER) container create \
		--platform "$(PROJ_PLATFORM_OS)/$(PROJ_PLATFORM_ARCH)" \
		--name "zabbix-server" \
		-h "zabbix-server" \
		-u "481" \
		--entrypoint "zabbix_server" \
		--net "$(NET_NAME)" \
		-p "10051":"10051" \
		--health-interval "10s" \
		--health-timeout "8s" \
		--health-retries "3" \
		--health-cmd "zabbix_server_healthcheck" \
		"$(IMG_REG_URL)/$(IMG_REPO):$(IMG_TAG_PFX)-$(PROJ_PLATFORM_OS)-$(PROJ_PLATFORM_ARCH)" \
		--foreground \
		-c "/usr/local/etc/zabbix/zabbix_server.conf"
	$(BIN_FIND) "bin" -mindepth "1" -type "f" -iname "*" -print0 \
	| $(BIN_TAR) -c --numeric-owner --owner "0" --group "0" -f "-" --null -T "-" \
	| $(BIN_DOCKER) container cp "-" "zabbix-server":"/usr/local"
	$(BIN_FIND) "etc/zabbix" -mindepth "1" -type "f" -iname "*" ! -iname "tls-key.pem" -print0 \
	| $(BIN_TAR) -c --numeric-owner --owner "0" --group "0" -f "-" --null -T "-" \
	| $(BIN_DOCKER) container cp "-" "zabbix-server":"/usr/local"
	$(BIN_FIND) "etc/zabbix" -mindepth "1" -type "f" -iname "tls-key.pem" -print0 \
	| $(BIN_TAR) -c --numeric-owner --owner "481" --group "481" --mode "600" -f "-" --null -T "-" \
	| $(BIN_DOCKER) container cp "-" "zabbix-server":"/usr/local"
	$(BIN_DOCKER) container start -a "zabbix-server"

.PHONY: container-server-run
container-server-run:
	$(MAKE) "container-server-run-$(PROJ_PLATFORM_OS)"

.PHONY: container-server-rm
container-server-rm:
	$(BIN_DOCKER) container rm -f "zabbix-server"

.PHONY: container-ui-run-linux
container-ui-run-linux:
	$(BIN_DOCKER) container create \
		--platform "$(PROJ_PLATFORM_OS)/$(PROJ_PLATFORM_ARCH)" \
		--rm \
		--name "zabbix-ui" \
		-h "zabbix-ui" \
		-u "480" \
		--entrypoint "httpd" \
		--net "$(NET_NAME)" \
		-p "443":"443" \
		--health-interval "10s" \
		--health-timeout "8s" \
		--health-retries "3" \
		--health-cmd "httpd-healthcheck \"443\" \"8\"" \
		"$(IMG_REG_URL)/$(IMG_REPO):$(IMG_TAG_PFX)-$(PROJ_PLATFORM_OS)-$(PROJ_PLATFORM_ARCH)" \
		-D "FOREGROUND" \
		-f "/usr/local/etc/httpd/httpd.conf"
	$(BIN_FIND) "etc/php81" -mindepth "1" -type "f" -iname "*" -print0 \
	| $(BIN_TAR) -c --numeric-owner --owner "0" --group "0" -f "-" --null -T "-" \
	| $(BIN_DOCKER) container cp "-" "zabbix-ui":"/"
	$(BIN_FIND) "etc/httpd" -mindepth "1" -type "f" -iname "*" ! -iname "tls-key.pem" -print0 \
	| $(BIN_TAR) -c --numeric-owner --owner "0" --group "0" -f "-" --null -T "-" \
	| $(BIN_DOCKER) container cp "-" "zabbix-ui":"/usr/local"
	$(BIN_FIND) "etc/httpd" -mindepth "1" -type "f" -iname "tls-key.pem" -print0 \
	| $(BIN_TAR) -c --numeric-owner --owner "480" --group "480" --mode "600" -f "-" --null -T "-" \
	| $(BIN_DOCKER) container cp "-" "zabbix-ui":"/usr/local"
	$(BIN_DOCKER) container start -a "zabbix-ui"

.PHONY: container-ui-run
container-ui-run:
	$(MAKE) "container-ui-run-$(PROJ_PLATFORM_OS)"

.PHONY: container-ui-rm
container-ui-rm:
	$(BIN_DOCKER) container rm -f "zabbix-ui"
