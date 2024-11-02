.PHONY: shell
.PHONY: clean
	
TOOLCHAIN_NAME=crossmix-toolchain
WORKSPACE_DIR := $(shell pwd)/workspace
TOOL=
DOCKER := $(shell command -v docker 2> /dev/null)
PODMAN := $(shell command -v podman 2> /dev/null)

.check:
ifdef DOCKER
    TOOL=docker
else ifdef PODMAN
    TOOL=podman
else
    $(error "Docker or Podman must be installed!")
endif

.build: .check Dockerfile
	@if [ -z "$$($(TOOL) images -q $(TOOLCHAIN_NAME))" ]; then \
		echo "Image not found, building..."; \
		mkdir -p ./workspace; \
		$(TOOL) build --platform linux/arm64 -t $(TOOLCHAIN_NAME) .; \
		touch .build; \
	else \
		echo "Image already exists, skipping build."; \
	fi


# additional slash at beginning is a hack to work in Windows + Git Bash
shell: .check .build
ifdef PODMAN
	@if ! $(TOOL) ps -a --format "{{.Names}}" | grep -q "^$(TOOLCHAIN_NAME)_container$$"; then \
		echo "Creating a new container..."; \
		$(TOOL) run -it --privileged --name $(TOOLCHAIN_NAME)_container -v /"$(WORKSPACE_DIR)":/root/workspace:z $(TOOLCHAIN_NAME) bash; \
	else \
		echo "Reusing existing container..."; \
		$(TOOL) start -i $(TOOLCHAIN_NAME)_container; \
	fi
else
	@if ! $(TOOL) ps -a --format "{{.Names}}" | grep -q "^$(TOOLCHAIN_NAME)_container$$"; then \
		echo "Creating a new container..."; \
		$(TOOL) run -it --privileged --name $(TOOLCHAIN_NAME)_container -v /"$(WORKSPACE_DIR)":/root/workspace $(TOOLCHAIN_NAME) bash; \
	else \
		echo "Reusing existing container..."; \
		$(TOOL) start -i $(TOOLCHAIN_NAME)_container; \
	fi
endif


clean: .check
	-$(TOOL) rm -f $(TOOLCHAIN_NAME)_container
	-$(TOOL) rmi $(TOOLCHAIN_NAME)
	rm -f .build
