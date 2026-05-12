SHELL := /bin/bash

ROOT_DIR := $(CURDIR)
SITE_DIR := $(ROOT_DIR)/site
MAVEN := $(ROOT_DIR)/mvnw
JAVA_HOME ?= $(shell brew --prefix openjdk@17 2>/dev/null)/libexec/openjdk.jdk/Contents/Home
SOLR_DOWNLOAD_URL ?= https://www.apache.si/lucene/solr/%s/solr-%s.%s
SPRING_ARGS ?= --blPU.hibernate.hbm2ddl.auto=update --solr.server.downloadUrl=$(SOLR_DOWNLOAD_URL)
APP_PORTS := 8000 8080 8443 8983

.PHONY: help build start stop status check-java

help:
	@echo "Available targets:"
	@echo "  make start   Start the storefront at https://localhost:8443"
	@echo "  make stop    Stop the storefront and embedded Solr processes"
	@echo "  make status  Show processes listening on app/Solr ports"
	@echo "  make build   Build all Maven modules without running tests"

check-java:
	@if [ -z "$(JAVA_HOME)" ] || [ ! -x "$(JAVA_HOME)/bin/java" ]; then \
		echo "Could not find Homebrew openjdk@17."; \
		echo "Install it with: brew install openjdk@17"; \
		exit 1; \
	fi

build: check-java
	@JAVA_HOME="$(JAVA_HOME)" PATH="$(JAVA_HOME)/bin:$$PATH" "$(MAVEN)" clean install -DskipTests

start: check-java
	@cd "$(SITE_DIR)" && JAVA_HOME="$(JAVA_HOME)" PATH="$(JAVA_HOME)/bin:$$PATH" "$(MAVEN)" spring-boot:run -Dspring-boot.run.arguments="$(SPRING_ARGS)"

stop:
	@pids="$$(for port in $(APP_PORTS); do lsof -tiTCP:$$port -sTCP:LISTEN; done | sort -u)"; \
	if [ -z "$$pids" ]; then \
		echo "No storefront or Solr processes are listening on ports: $(APP_PORTS)"; \
	else \
		echo "Stopping processes: $$pids"; \
		kill $$pids; \
	fi

status:
	@for port in $(APP_PORTS); do \
		echo "Port $$port:"; \
		lsof -nP -iTCP:$$port -sTCP:LISTEN || true; \
	done
