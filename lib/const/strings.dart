// 개인정보 수집 및 이용 동의
import 'package:ac_project_app/gen/assets.gen.dart';
import 'package:ac_project_app/models/tutorial/tutorial.dart';

const approveFirstLink =
    'https://plip.kr/html/2e555eb1-0d11-48d2-9756-22e3bad18fb0.html';

// 이용 약관
const approveSecondLink =
    'https://linkpoolpd.notion.site/LINKPOOL-6f28bbd4f0914ffdad1614a3655d06fa';

// 개인정보 처리방침
const personalInfoLink =
    'https://linkpoolpd.notion.site/LINKPOOL-71b2b45eda864d91882a6995bf20413f';

// 도움말
const helpLink =
    'https://linkpoolpd.notion.site/c6ea6729dfac4dbc89c95d294bca43f8';

// API LINK
const baseUrl = 'https://api.linkpool.co.kr';

//warning message
const warningMsgTitle = '링크풀은 건전한 링크 관리 및 공유 문화를 지향해요';

//warning message
const warningMsgContent =
    '부적절하거나 불쾌감을 주는 공개 컨텐츠는 제재를 받을 수 있어요 \n링크풀과 함께 유익하고 건전한 공유 문화를 만들어가 주세요';

final tutorials = [
  Tutorial(
    Assets.tutorials.tutorial1.path,
    '즉시 저장 가능한 링크',
    '검색하다 발견한 인사이트를\n간편하게 저장해보세요',
  ),
  Tutorial(
    Assets.tutorials.tutorial2.path,
    '폴더링으로 링크분류',
    '링크를 카테고리별로 분류하고\n쉽게 찾아보세요',
  ),
  Tutorial(
    Assets.tutorials.tutorial3.path,
    '보기 쉬운 링크 관리',
    '차곡차곡 정리해둔 내 링크\n언제든지 한 눈에 볼 수 있어요',
  ),
  Tutorial(
    Assets.tutorials.tutorial4.path,
    '노트로 상세한 기억 저장',
    '방금 떠오른 아이디어,\n잊지 않도록 링크 노트에 메모해 보세요',
  ),
];

const emptyLinksString = '등록된 링크가 없습니다';
