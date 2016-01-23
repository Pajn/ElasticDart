library elastic_dart.warehouse_conformance;

import 'package:elastic_dart/warehouse.dart';
import 'package:warehouse/adapters/conformance_tests.dart';
import 'package:warehouse/src/adapters/conformance_tests/domain.dart';

main() {
  var db = new Elasticsearch('http://172.17.0.2:9200');
  runConformanceTests(
      () => new ElasticSession(db, indices: {
        AnimatedMovie: 'movie',
        Child: 'base',
      }),
      (session, type) => new ElasticRepository.withType(session, type),
      testTimeout: const Duration(seconds: 10)
  );
}
