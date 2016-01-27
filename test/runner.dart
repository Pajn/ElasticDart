import 'package:unittest/unittest.dart' show unittestConfiguration;

import 'helpers/testdata.dart';
import 'specs/elasticsearch.dart' as elasticsearch;
import 'specs/warehouse/warehouse.dart' as warehouse;
import 'warehouse_conformance.dart' as warehouse_conformance;
import 'package:elastic_dart/elastic_dart.dart';

main() async {
  await setUpTestData();
  final es = new Elasticsearch();

  unittestConfiguration.timeout = const Duration(seconds: 5);

  elasticsearch.main(es);
  warehouse.main(es);
  warehouse_conformance.main(es);
}
