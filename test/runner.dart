import 'package:unittest/unittest.dart' show unittestConfiguration;

import 'specs/elasticsearch.dart' as elasticsearch;
import 'specs/warehouse/warehouse.dart' as warehouse;
import 'warehouse_conformance.dart' as warehouse_conformance;
import 'package:elastic_dart/elastic_dart.dart';
import 'helpers/testdata.dart';

main() async {
  final es = new Elasticsearch();
  await cleanUpTestData();

  unittestConfiguration.timeout = const Duration(seconds: 5);

  await warehouse_conformance.main(es);

  elasticsearch.main(es);
  warehouse.main(es);
}
