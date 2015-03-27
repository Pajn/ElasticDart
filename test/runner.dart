import 'dart:async';
import 'helpers/testdata.dart';
import 'specs/elastic.dart' as elastic;

main() async {
  await setUpTestData();
  // Wait for elastic to index the new documents
  await new Future.delayed(new Duration(seconds: 2));

  elastic.main();
}