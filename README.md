# Adding Python Unit Tests

I just added some basic unit tests for a project at work ([managed-cluster-config-webhooks](https://github.com/openshift/managed-cluster-validating-webhooks)) and it was super easy to add.  This repo was created to share how easy it is to setup and use.

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

# Run Tests

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
