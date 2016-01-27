library elastic_dart.warehouse_conformance;

import 'package:elastic_dart/warehouse.dart';
import 'package:warehouse/adapters/conformance_tests.dart';
import 'package:warehouse/src/adapters/conformance_tests/domain.dart';

main([Elasticsearch es]) async {
  final db = es ?? new Elasticsearch('http://127.0.0.1:9200');

  createSession() => new ElasticDbSession(db, indices: {
    AnimatedMovie: 'movie',
    Child: 'base',
  });

  final session = createSession();
  final titleMapping = {
    'title': {
      'type': 'string',
      'index': 'not_analyzed',
    }
  };

  await session.db.createIndex('movie', throwIfExists: false);
  await session.mapType(Movie, titleMapping);
  await session.mapType(AnimatedMovie, titleMapping);

  runConformanceTests(
      createSession,
      (session, type) => new ElasticRepository.withType(session, type),
      testTimeout: const Duration(seconds: 10)
  );
}
