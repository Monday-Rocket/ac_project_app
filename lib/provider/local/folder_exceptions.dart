/// LocalFolderRepository의 도메인 검증 예외들.
/// Error 계열이 아니라 Exception 계열 — 예상 가능한 애플리케이션 조건.
abstract class FolderException implements Exception {
  const FolderException(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// 같은 부모 아래에 동일한 이름의 폴더가 이미 있다.
class SiblingNameTakenException extends FolderException {
  const SiblingNameTakenException(super.message);
}

/// 지정한 부모 폴더가 존재하지 않는다.
class ParentNotFoundException extends FolderException {
  const ParentNotFoundException(super.message);
}

/// 부모가 시스템 관리 폴더(미분류)라 하위 생성 불가.
class ParentNotClassifiedException extends FolderException {
  const ParentNotClassifiedException(super.message);
}

/// 새 폴더 자체가 is_classified=false — 미분류 폴더는 시스템만 생성.
class UnclassifiedCreationException extends FolderException {
  const UnclassifiedCreationException(super.message);
}
