# Adding Python Unit Tests

I just added some basic unit tests for a project ([managed-cluster-config-webhooks](https://github.com/openshift/managed-cluster-validating-webhooks)) and it was super easy to add.  This repo was created to share how easy it is to setup and use.

**NOTE** the [PR](https://github.com/openshift/managed-cluster-validating-webhooks/pull/40) including the test isn't merged as of writing this.. things may change based on review.

## Make Code Testable

The biggest thing is having a function that you can test.  Recommend you break up logic into a set of testable functions.  Functions should have no side effect and have a clear response that can be assessed for correctness.

## Add A Test

This is so simple it blows my mind…

1. import unittest
1. subclass unittest.TestCase
1. write test functions
1. add a test make target

Here's a very simple example you can drop into your source just to try it out:

```python
import unittest

class TestMyStuff(unittest.TestCase):
    def test_success(self):
        self.assertTrue(True) # will pass

    def test_failure(self):
        self.assertFalse(True) # will fail
```

This file should be placed in the same source tree as your testable code so it can be loaded.  See [src/test_example.py](src/test_example.py)

## Run Tests

You can run ALL the tests in a directory with: `python -m unittest discover <directory>`

In this example that means:

```bash
python -m unittest discover src
```

I like make, so I add this target to the [Makefile](Makefile):

```
.PHONY: test
test:
	python -m unittest discover src
```

Consider making tests run before every build of your source!

And run the tests!  Remember one of our tests here is going to fail.

```bash
$ make test
python -m unittest discover src -vvv
test_failure (test_example.TestMyStuff) ... FAIL
test_success (test_example.TestMyStuff) ... ok

======================================================================
FAIL: test_failure (test_example.TestMyStuff)
----------------------------------------------------------------------
Traceback (most recent call last):
  File ".../python-unittest/src/test_example.py", line 8, in test_failure
    self.assertFalse(True) # will fail
AssertionError: True is not false

----------------------------------------------------------------------
Ran 2 tests in 0.001s

FAILED (failures=1)
make: *** [Makefile:3: test] Error 1
```

## Run Tests: In a Container

To make sure the tests can run anywhere it's a good idea to run them in a container.

```bash
podman run --rm -v `pwd -P`:`pwd -P` python:3 /bin/sh -c "cd `pwd`; python -m unittest discover src -vvv"
```

This is also added as a make target `test-container`.  We get the same result but now it's portable!

```bash
$ make test-container
podman run --rm -v `pwd -P`:`pwd -P` python:3 /bin/sh -c "cd `pwd`; python -m unittest discover src -vvv"; \

test_failure (test_example.TestMyStuff) ... FAIL
test_success (test_example.TestMyStuff) ... ok

======================================================================
FAIL: test_failure (test_example.TestMyStuff)
----------------------------------------------------------------------
Traceback (most recent call last):
  File ".../python-unittest/src/test_example.py", line 8, in test_failure
    self.assertFalse(True) # will fail
AssertionError: True is not false

----------------------------------------------------------------------
Ran 2 tests in 0.001s

FAILED (failures=1)
make: *** [Makefile:10: test-container] Error 1
```

## Run Tests: In a Container With Dependencies

If you have dependencies it is annoying to install them in a fresh base container for every test run.  Instead, pre-build the test image with dependencies!  For this you need to:

1. have a way to delete your test container
1. build the test container
1. use the test container

To delete it we create a `make clean` target:

```
.PHONY: clean
clean:
    $(CONTAINER_ENGINE) rmi $(REPO_NAME):test || true
```

To build the test conatiner we need a [Dockerfile](build/Dockerfile.test):

```
FROM python:3

# Install modules
COPY requirements.txt ./
RUN pip install -r requirements.txt
```

A make target to build the test container:

```
.PHONY: build-test-container
build-test-container:
	$(CONTAINER_ENGINE) build -t $(REPO_NAME):test -f build/Dockerfile.test .
```

And, finally, update `test-container` to use the new container:

```
.PHONY: test-container
test-container: build-test-container
	$(CONTAINER_ENGINE) run --rm -v `pwd -P`:`pwd -P` $(REPO_NAME):test /bin/sh -c "cd `pwd`; python -m unittest discover src -vvv"; \
```

First time you test the container is created.  For me it takes 21 seconds:

```bash
$ make test-container
podman build -t python-unittest:test -f build/Dockerfile.test .
STEP 1: FROM python:3
STEP 2: COPY requirements.txt ./
--> cbe94584988
STEP 3: RUN pip install -r requirements.txt
Collecting semver==2.8.1
  Downloading semver-2.8.1-py2.py3-none-any.whl (5.1 kB)
Installing collected packages: semver
Successfully installed semver-2.8.1
STEP 4: COMMIT python-unittest:test
--> 162864bf5c4
162864bf5c46cad562ac1fcf932ced4dd2960fd4149b79d96684f2b9adaad920
podman run --rm -v `pwd -P`:`pwd -P` python-unittest:test /bin/sh -c "cd `pwd`; python -m unittest discover src -vvv"; \

test_major (test_modules.TestModules) ... ok
test_failure (test_example.TestMyStuff) ... FAIL
test_success (test_example.TestMyStuff) ... ok

======================================================================
FAIL: test_failure (test_example.TestMyStuff)
----------------------------------------------------------------------
Traceback (most recent call last):
  File ".../python-unittest/src/test_example.py", line 8, in test_failure
    self.assertFalse(True) # will fail
AssertionError: True is not false

----------------------------------------------------------------------
Ran 3 tests in 0.001s

FAILED (failures=1)
make: *** [Makefile:22: test-container] Error 1
real 20.53
user 8.18
sys 5.66
```

And it is reused on subsequent runs is faster, 2 seconds:

```bash
$ time -p make test-container
podman build -t python-unittest:test -f build/Dockerfile.test .
STEP 1: FROM python:3
STEP 2: COPY requirements.txt ./
--> Using cache ec767d77b7950cc3afa3e21fae8441ac49f94205d18e6cef086d62d2b998dff3
STEP 3: RUN pip install -r requirements.txt
--> Using cache e41a6f015adbb66e3a0817a54bc5cae8346bc9c6916b08a27836bf3af6090b7a
STEP 4: COMMIT python-unittest:test
--> e41a6f015ad
e41a6f015adbb66e3a0817a54bc5cae8346bc9c6916b08a27836bf3af6090b7a
podman run --rm -v `pwd -P`:`pwd -P` python-unittest:test /bin/sh -c "cd `pwd`; python -m unittest discover src -vvv"; \

test_major (test_modules.TestModules) ... ok
test_failure (test_example.TestMyStuff) ... FAIL
test_success (test_example.TestMyStuff) ... ok

======================================================================
FAIL: test_failure (test_example.TestMyStuff)
----------------------------------------------------------------------
Traceback (most recent call last):
  File ".../python-unittest/src/test_example.py", line 8, in test_failure
    self.assertFalse(True) # will fail
AssertionError: True is not false

----------------------------------------------------------------------
Ran 3 tests in 0.001s

FAILED (failures=1)
make: *** [Makefile:22: test-container] Error 1
real 1.71
user 0.78
sys 0.37
```

