# the name of this repo.. used for images
REPO_NAME?=python-unittest

# allow overriding to something like "python"
CONTAINER_ENGINE?=docker

default: test-container

# very simple test, only use if dependencies are installed locally
.PHONY: test
test:
	python -m unittest discover src -vvv

# build the test container
.PHONY: build-test-container
build-test-container:
	$(CONTAINER_ENGINE) build -t $(REPO_NAME):test -f build/Dockerfile.test .

# use the test container to run a test
.PHONY: test-container
test-container: build-test-container
	$(CONTAINER_ENGINE) run --rm -v `pwd -P`:`pwd -P` $(REPO_NAME):test /bin/sh -c "cd `pwd`; python -m unittest discover src -vvv"; \

# clean anything we have created
.PHONY: clean
clean:
	$(CONTAINER_ENGINE) rmi $(REPO_NAME):test || true

# make requirements, must have pipreqs installed
.PHONY: requirements
requirements:
	pipreqs ./ --force