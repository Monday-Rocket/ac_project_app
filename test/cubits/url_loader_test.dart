import 'package:ac_project_app/cubits/url_data_cubit.dart';
import 'package:ac_project_app/util/logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('open graph load success url test', () async {
    const loadSuccessUrl = 'https://bside.best/';

    final loadResult = await UrlLoader.loadData(loadSuccessUrl);

    final expected = {
      'title': '비사이드 : IT 프로젝트 경험을 통해 성장하세요!',
      'description': null,
      'image':
          'https://bsidebest.s3.ap-northeast-2.amazonaws.com/asset/images/og-image.png',
      'url': loadSuccessUrl
    };
    expect(loadResult.toJson(), expected);
  });

  test('open graph extract success url test', () async {
    const extractSuccessUrl = 'https://naver.me/GUDWG42d';

    final loadResult = await UrlLoader.loadData(extractSuccessUrl);
    final failExpected = {
      'title': '네이버',
      'description': null,
      'image':
          'https://bridge.naver.com/static/images/ico_sn_naver_app.png?v=20210826193421',
      'url': null,
    };

    final successExpected = {
      'title': 'ok : 네이버 통합검색',
      'description': "'ok'의 네이버 통합검색 결과입니다.",
      'image': 'https://ssl.pstatic.net/sstatic/search/common/og_v3.png',
      'url': 'https://naver.me/GUDWG42d'
    };

    Log.i(loadResult.toJson());
    expect(loadResult.toJson(), failExpected, skip: '그냥 데이터 뽑으면 맞지 않음');
    expect(loadResult.toJson(), successExpected);
  });
}
