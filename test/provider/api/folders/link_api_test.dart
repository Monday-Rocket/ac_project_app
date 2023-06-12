import 'dart:convert';

import 'package:ac_project_app/cubits/links/upload_result_state.dart';
import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/models/link/searched_links.dart';
import 'package:ac_project_app/models/net/api_result.dart';
import 'package:ac_project_app/provider/api/custom_client.dart';
import 'package:ac_project_app/provider/api/folders/link_api.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';

import '../mock_client_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('getLinksFromSelectedFolder success test', () async {
    final apiExpected = ApiResult(
      status: 0,
      data: const SearchedLinks(
        pageNum: 0,
        pageSize: 10,
        totalCount: 2,
        totalPage: 1,
        contents: [
          Link(
            id: 1,
            title: '링크제목1',
            url: 'https://www.naver.com',
            time: '2023-05-15T10:30:00.861975',
            folderId: 1,
          ),
          Link(
            id: 2,
            title: '링크제목2',
            url: 'https://www.naver.com',
            time: '2023-05-15T10:30:00.861975',
            folderId: 1,
          ),
        ],
      ),
    );

    final folder = Folder(
      id: 1,
      thumbnail: '01',
      visible: true,
      name: '폴더명1',
      links: 2,
      time: '2023-05-15T10:30:00.861975',
    );

    const pageNum = 0;

    final mockClient = getMockClient(
      apiExpected,
      '/folders/${folder.id}/links?page_no=$pageNum&page_size=10',
    );
    final api = getLinkApi(mockClient);
    final result = await api.getLinksFromSelectedFolder(folder, pageNum);

    result.when(
      success: (data) => expect(data, apiExpected.data),
      error: fail,
    );
  });

  test('postLink success test', () async {
    final apiExpected = ApiResult(status: 0);

    const link = Link(
      id: 1,
      title: '링크제목1',
      url: 'https://www.naver.com',
      time: '2023-05-15T10:30:00.861975',
      folderId: 1,
    );

    final mockClient = getMockClient(apiExpected, '/links');
    final api = getLinkApi(mockClient);
    final result = await api.postLink(link);
    expect(result, UploadResultState.success);
  });

  // postLink fail test
  test('postLink apiError test', () async {
    final apiExpected = ApiResult(
      status: 1,
    );

    const link = Link(
      id: 1,
      title: '링크제목1',
      url: 'https://www.naver.com',
      time: '2023-05-15T10:30:00.861975',
      folderId: 1,
    );

    final mockClient = getMockClient(apiExpected, '/links');
    final api = getLinkApi(mockClient);
    final result = await api.postLink(link);
    expect(result, UploadResultState.apiError);
  });

  test('postLink duplicated test', () async {
    final apiExpected = ApiResult(status: 0);

    const link = Link();

    final mockClient = getMockClient(
      apiExpected,
      '/links',
      hasError: true,
      errorCode: 400,
      errorMessage: jsonEncode(
        ApiResult(
          status: 3000,
          message: '이미 등록된 url입니다.',
        ).toJson(),
      ),
    );
    final api = getLinkApi(mockClient);
    final result = await api.postLink(link);
    expect(result, UploadResultState.duplicated);
  });

  test('patchLink success test', () async {
    final apiExpected = ApiResult(status: 0);

    const link = Link(
      id: 1,
      title: '수정된 링크제목',
      url: 'https://www.naver.com',
      time: '2023-05-15T10:30:00.861975',
      folderId: 1,
    );

    final mockClient = getMockClient(apiExpected, '/links/${link.id}');

    final api = getLinkApi(mockClient);
    final result = await api.patchLink(link);
    expect(result, true);
  });

  test('patchLink fail test', () async {
    final apiExpected = ApiResult(
      status: 1,
    );

    const link = Link(
      id: 1,
      title: '수정된 링크제목',
      url: 'https://www.naver.com',
      time: '2023-05-15T10:30:00.861975',
      folderId: 1,
    );

    final mockClient = getMockClient(apiExpected, '/links/${link.id}');

    final api = getLinkApi(mockClient);
    final result = await api.patchLink(link);
    expect(result, false);
  });

  test('getJobGroupLinks success test', () async {
    final apiExpected = ApiResult(
      status: 0,
      data: const SearchedLinks(
        pageNum: 0,
        pageSize: 10,
        totalCount: 2,
        totalPage: 1,
        contents: [
          Link(
            id: 1,
            title: '링크제목1',
            url: 'https://www.naver.com',
            time: '2023-05-15T10:30:00.861975',
            folderId: 1,
          ),
          Link(
            id: 2,
            title: '링크제목2',
            url: 'https://www.naver.com',
            time: '2023-05-15T10:30:00.861975',
            folderId: 1,
          ),
        ],
      ),
    );

    const jobGroup = 1;
    const pageNum = 0;

    final mockClient = getMockClient(
      apiExpected,
      '/job-groups/$jobGroup/links?'
      'page_no=$pageNum&'
      'page_size=10',
    );
    final api = getLinkApi(mockClient);
    final result = await api.getJobGroupLinks(jobGroup, pageNum);

    result.when(
      success: (data) => expect(data, apiExpected.data),
      error: fail,
    );
  });

  // getJobGroupLinks fail test
  test('getJobGroupLinks apiError test', () async {
    final apiExpected = ApiResult(
      status: 1,
      message: '404',
    );

    const jobGroup = 1;
    const pageNum = 0;

    final mockClient = getMockClient(
      apiExpected,
      '/job-groups/$jobGroup/links?'
      'page_no=$pageNum&'
      'page_size=10',
      hasError: true,
    );
    final api = getLinkApi(mockClient);
    final result = await api.getJobGroupLinks(jobGroup, pageNum);

    result.when(
      success: (_) => fail('should be error'),
      error: (e) => expect(e, apiExpected.message),
    );
  });

  test('getUnClassifiedLinks success test', () async {
    final apiExpected = ApiResult(
      status: 0,
      data: const SearchedLinks(
        pageNum: 0,
        pageSize: 10,
        totalCount: 2,
        totalPage: 1,
        contents: [
          Link(
            id: 1,
            title: '링크제목1',
            url: 'https://www.naver.com',
            time: '2023-05-15T10:30:00.861975',
          ),
          Link(
            id: 2,
            title: '링크제목2',
            url: 'https://www.naver.com',
            time: '2023-05-15T10:30:00.861975',
          ),
        ],
      ),
    );

    const pageNum = 0;

    final mockClient = getMockClient(
      apiExpected,
      '/links/unclassified?page_no=$pageNum&page_size=10',
    );
    final api = getLinkApi(mockClient);
    final result = await api.getUnClassifiedLinks(pageNum);

    result.when(
      success: (data) => expect(data, apiExpected.data),
      error: fail,
    );
  });

  test('deleteLink Success Test', () async {
    final apiExpected = ApiResult(
      status: 0,
    );

    const link = Link(
      id: 1,
      title: '링크제목1',
      url: 'https://www.naver.com',
      time: '2023-05-15T10:30:00.861975',
    );

    final mockClient = getMockClient(apiExpected, '/links/${link.id}');
    final api = getLinkApi(mockClient);
    final result = await api.deleteLink(link);

    expect(result, true);
  });
  
  test('searchOtherLinks success test', () async {
    final apiExpected = ApiResult(
      status: 0,
      data: const SearchedLinks(
        pageNum: 0,
        pageSize: 10,
        totalCount: 2,
        totalPage: 1,
        contents: [
          Link(
            id: 3,
            title: 'keyword1',
            url: 'https://www.naver.com',
            time: '2023-05-15T10:30:00.861975',
            folderId: 1,
          ),
          Link(
            id: 4,
            title: 'keyword2',
            url: 'https://www.naver.com',
            time: '2023-05-15T10:30:00.861975',
            folderId: 1,
          ),
        ],
      ),
    );

    const keyword = 'keyword';
    const pageNum = 0;

    final mockClient = getMockClient(
      apiExpected,
      '/links/search?'
          'my_links_only=false&'
          'keyword=$keyword&'
          'page_no=$pageNum&'
          'page_size=10',
    );
    final api = getLinkApi(mockClient);
    final result = await api.searchOtherLinks(keyword, pageNum);

    result.when(
      success: (data) => expect(data, apiExpected.data),
      error: fail,
    );
  });

  test('search my links', () async {
    final apiExpected = ApiResult(
      status: 0,
      data: const SearchedLinks(
        pageNum: 0,
        pageSize: 10,
        totalCount: 2,
        totalPage: 1,
        contents: [
          Link(
            id: 3,
            title: 'keyword1',
            url: 'https://www.naver.com',
            time: '2023-05-15T10:30:00.861975',
            folderId: 1,
          ),
          Link(
            id: 4,
            title: 'keyword2',
            url: 'https://www.naver.com',
            time: '2023-05-15T10:30:00.861975',
            folderId: 1,
          ),
        ],
      ),
    );

    const keyword = 'keyword';
    const pageNum = 0;

    final mockClient = getMockClient(
      apiExpected,
      '/links/search?'
          'my_links_only=true&'
          'keyword=$keyword&'
          'page_no=$pageNum&'
          'page_size=10',
    );
    final api = getLinkApi(mockClient);
    final result = await api.searchMyLinks(keyword, pageNum);

    result.when(
      success: (data) => expect(data, apiExpected.data),
      error: fail,
    );
  });

  test('changeFolder success test', () async {
    final apiExpected = ApiResult(
      status: 0,
    );

    const link = Link(
      id: 1,
      title: '링크제목1',
      url: 'https://www.naver.com',
      time: '2023-05-15T10:30:00.861975',
      folderId: 1,
    );

    final mockClient = getMockClient(apiExpected, '/links/${link.id}');
    final api = getLinkApi(mockClient);
    final result = await api.changeFolder(link, 2);

    expect(result, true);
  });
}

LinkApi getLinkApi(MockClient mockClient) {
  return LinkApi(
    CustomClient(
      client: mockClient,
      auth: MockFirebaseAuth(
        mockUser: MockUser(
          isAnonymous: true,
        ),
      ),
    ),
  );
}
