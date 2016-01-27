import 'package:unittest/unittest.dart' show unittestConfiguration;
import 'package:http/browser_client.dart';

import 'helpers/testdata.dart' as testdata;
import 'specs/elasticsearch.dart' as elasticsearch;
import 'package:elastic_dart/browser_client.dart';

main() async {
  testdata.client = new BrowserClient();
  await testdata.cleanUpTestData();

  unittestConfiguration.timeout = const Duration(seconds: 5);

  elasticsearch.main(new Elasticsearch());
}
