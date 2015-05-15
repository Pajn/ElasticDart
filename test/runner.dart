import 'dart:async';
import 'package:unittest/unittest.dart' show unittestConfiguration;

import 'helpers/testdata.dart';
import 'specs/elastic_search.dart' as elastic_search;

main() async {
  await setUpTestData();
  // Wait for elastic to index the new documents
  await new Future.delayed(new Duration(seconds: 2));

  unittestConfiguration.timeout = const Duration(seconds: 3);

  elastic_search.main();
}
