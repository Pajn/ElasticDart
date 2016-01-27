library elastic_dart.test.warehouse;

import 'dart:async';
import 'package:guinness/guinness.dart';
import 'package:warehouse/mocks.dart';
import 'package:warehouse/warehouse.dart';

import 'package:elastic_dart/warehouse.dart';
import '../../helpers/domain.dart';

main(Elasticsearch es) {
  describe('Warehouse companion', () {
    DbSession session;
    CinemaRepository cinemaRepository;
    GenericRepository combinedRepository, customCombinedIndex;
    MovieRepository customMovieIndex, movieRepository;
    Cinema realMovies, theCinema;
    Movie avatar, killBill, killBill2, pulpFiction, theHobbit;

    Future storeAndSave() async {
      session.store(realMovies);
      session.store(theCinema);

      session.store(avatar);
      session.store(killBill);
      session.store(killBill2);
      session.store(pulpFiction);
      session.store(theHobbit);

      await session.saveChanges();
      // wait for the changes to be persisted
      await new Future.delayed(new Duration(seconds: 2));
    }

    beforeEach(() async {
      await es.deleteIndex('_all');
      session = new MockSession();
      cinemaRepository = new CinemaRepository(session);
      combinedRepository = new GenericRepository(session, const [Cinema, Movie]);
      customCombinedIndex = new CustomGenericIndex(session, const [Cinema, Movie]);
      customMovieIndex = new CustomMovieIndex(session);
      movieRepository = new MovieRepository(session);

      realMovies = new Cinema()
        ..name = 'Real Movies'
        ..location = new GeoPoint(14, 37);

      theCinema = new Cinema()
        ..name = 'The Cinema'
        ..location = new GeoPoint(10, 50);

      avatar = new Movie()
        ..title = 'Avatar';

      killBill = new Movie()
        ..title = 'Kill Bill - Vol. 1';

      killBill2 = new Movie()
        ..title = 'Kill Bill - Vol. 2';

      pulpFiction = new Movie()
        ..title = 'Pulp Fiction';

      theHobbit = new Movie()
        ..title = 'The Hobbit: An Unexpected Journey';
    });

    it('should be able to use a custom index name', () async {
      await session.registerCompanion(Elasticsearch, elasticsearchCompanion(es, {
        'movies': {
          Movie: (Movie movie) => {'title': movie.title}
        },
      }));

      await storeAndSave();

      var entities = await customMovieIndex.search('Bill');

      expect(entities.map((entity) => entity.title).toList()..sort()).toEqual([
        'Kill Bill - Vol. 1',
        'Kill Bill - Vol. 2',
      ]);

      await movieRepository.search('Bill')
        .then((_) => 'Should have thrown')
        .catchError((e) {
          expect(e).toBeA(IndexMissingException);
        });
    });

    it('should be able to use a custom index name with combined indices', () async {
      await session.registerCompanion(Elasticsearch, elasticsearchCompanion(es, {
        'movies': {
          Cinema: (Cinema cinema) => {'name': cinema.name},
          Movie: (Movie movie) => {'title': movie.title}
        },
      }));

      await storeAndSave();
      var entities = await customCombinedIndex.search('The');

      expect(entities[0].name).toEqual('The Cinema');
      expect(entities[1].title).toEqual('The Hobbit: An Unexpected Journey');
    });

    it('should be able to use combined indices', () async {
      await session.registerCompanion(Elasticsearch, elasticsearchCompanion(es, {
        [Cinema, Movie]: fullDocument(),
      }));

      await storeAndSave();
      var entities = await combinedRepository.search('The');

      entities.sort((a, b) => (a is Cinema ? a.name : a.title)
          .compareTo(b is Cinema ? b.name : b.title));

      expect(entities[0].name).toEqual('The Cinema');
      expect(entities[1].title).toEqual('The Hobbit: An Unexpected Journey');
    });

    it('should be able to use combined indices with individual format', () async {
      await session.registerCompanion(Elasticsearch, elasticsearchCompanion(es, {
        [Cinema, Movie]: {
          Cinema: (Cinema cinema) => {'name': cinema.name},
          Movie: (Movie movie) => {'title': movie.title}
        },
      }));

      await storeAndSave();
      var entities = await combinedRepository.search('The');

      entities.sort((a, b) => (a is Cinema ? a.name : a.title)
          .compareTo(b is Cinema ? b.name : b.title));

      expect(entities[0].name).toEqual('The Cinema');
      expect(entities[1].title).toEqual('The Hobbit: An Unexpected Journey');
    });

    it('should map GeoPoints', () async {
      await session.registerCompanion(Elasticsearch, elasticsearchCompanion(es, {
        Cinema: fullDocument(),
      }));

      await storeAndSave();
      var entities = await cinemaRepository.near(new GeoPoint(11, 48));

      expect(entities.map((entity) => entity.name)).toEqual([
        'The Cinema',
        'Real Movies',
      ]);
    });

    describe('mirroring', () {
      beforeEach(() async {
        await session.registerCompanion(Elasticsearch, elasticsearchCompanion(es, {
          Movie: (Movie movie) => {'title': movie.title},
        }));

        await storeAndSave();
      });

      it('should be able to search for created movies', () async {
        var entities = await movieRepository.search('Bill');

        expect(entities.map((entity) => entity.title).toList()..sort()).toEqual([
          'Kill Bill - Vol. 1',
          'Kill Bill - Vol. 2',
        ]);
      });

      it('should be able to search for updated movies', () async {
        avatar.title = 'Avatar - bill';
        session.store(avatar);
        await session.saveChanges();
        // wait for the changes to be persisted
        await new Future.delayed(new Duration(seconds: 2));

        var entities = await movieRepository.search('Bill');

        expect(entities.map((entity) => entity.title).toList()..sort()).toEqual([
          'Avatar - bill',
          'Kill Bill - Vol. 1',
          'Kill Bill - Vol. 2',
        ]);
      });

      it('should not be able to search for deleted movies', () async {
        session.delete(killBill);
        await session.saveChanges();
        // wait for the changes to be persisted
        await new Future.delayed(new Duration(seconds: 2));

        var entities = await movieRepository.search('Bill');

        expect(entities.map((entity) => entity.title)).toEqual([
          'Kill Bill - Vol. 2',
        ]);
      });
    });
  });
}
