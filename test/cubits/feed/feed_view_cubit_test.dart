import 'package:ac_project_app/cubits/feed/feed_view_cubit.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

class MockFeedViewCubit extends MockCubit<List<Link>> implements FeedViewCubit {}

void main() {

  group('getLinks', () {
    test('getLinks success test', () async {
      // final cubit = MockFeedViewCubit();
    });
  });

}
