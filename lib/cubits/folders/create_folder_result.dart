/// 폴더 생성 결과. 시트가 원인별 에러 메시지를 선택할 수 있게 구분 전달.
sealed class CreateFolderResult {
  const CreateFolderResult();
}

class Created extends CreateFolderResult {
  const Created(this.id);
  final int id;
}

class DuplicateSibling extends CreateFolderResult {
  const DuplicateSibling();
}

class ParentMissing extends CreateFolderResult {
  const ParentMissing();
}

class CreateFolderFailed extends CreateFolderResult {
  const CreateFolderFailed(this.error);
  final Object error;
}
