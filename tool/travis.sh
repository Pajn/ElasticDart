#!/bin/bash

# Fast fail the script on failures.
set -e

# Run the tests.
if [ "$TRAVIS_DART_VERSION" == "stable" ]; then
    dart --checked --enable-async test/runner.dart
else
    dart --checked test/runner.dart

    # If the COVERALLS_TOKEN token is set on travis
    # Install dart_coveralls
    # Rerun tests with coverage and send to coveralls
    if [ "$COVERALLS_TOKEN" ]; then
      pub global activate dart_coveralls
      pub global run dart_coveralls report \
        --token $COVERALLS_TOKEN \
        --retry 2 \
        --exclude-test-files \
        test/runner.dart
    fi
fi
