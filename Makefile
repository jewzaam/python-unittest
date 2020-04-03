# allow overriding to something like "python"
CONTAINER_ENGINE?=docker

.PHONY: test
test:
	python -m unittest discover src -vvv

.PHONY: test-container
test-container:
	$(CONTAINER_ENGINE) run --rm -v `pwd -P`:`pwd -P` python:3 /bin/sh -c "cd `pwd`; python -m unittest discover src -vvv"; \
