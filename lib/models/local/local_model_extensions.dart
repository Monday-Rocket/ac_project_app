import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/models/local/local_folder.dart';
import 'package:ac_project_app/models/local/local_link.dart';

/// LocalFolder를 기존 Folder 모델로 변환하는 확장
extension LocalFolderToFolder on LocalFolder {
  Folder toFolder() {
    return Folder(
      id: id,
      thumbnail: thumbnail,
      visible: isClassified,
      name: name,
      links: linksCount ?? 0,
      time: createdAt,
      isClassified: isClassified,
      isAdmin: true, // 로컬에서는 항상 관리자
      shared: false, // 오프라인 모드에서는 공유 기능 없음
      membersCount: 0,
    );
  }
}

/// LocalLink를 기존 Link 모델로 변환하는 확장
extension LocalLinkToLink on LocalLink {
  Link toLink() {
    return Link(
      id: id,
      url: url,
      title: title,
      image: image,
      describe: describe,
      folderId: folderId,
      time: createdAt,
      // user는 로컬에서 사용하지 않음 (기본값 null)
      inflowType: inflowType,
    );
  }
}

/// Folder를 LocalFolder로 변환하는 확장
extension FolderToLocalFolder on Folder {
  LocalFolder toLocalFolder() {
    final now = DateTime.now().toIso8601String();
    return LocalFolder(
      id: id,
      name: name ?? '폴더',
      thumbnail: thumbnail,
      isClassified: visible ?? isClassified ?? true,
      createdAt: time ?? now,
      updatedAt: now,
      linksCount: links,
    );
  }
}

/// Link를 LocalLink로 변환하는 확장
extension LinkToLocalLink on Link {
  LocalLink toLocalLink({required int targetFolderId}) {
    final now = DateTime.now().toIso8601String();
    return LocalLink(
      id: id,
      folderId: folderId ?? targetFolderId,
      url: url ?? '',
      title: title,
      image: image,
      describe: describe,
      inflowType: inflowType,
      createdAt: time ?? now,
      updatedAt: now,
    );
  }
}

/// List 변환 헬퍼
extension LocalFolderListExtension on List<LocalFolder> {
  List<Folder> toFolderList() => map((f) => f.toFolder()).toList();
}

extension LocalLinkListExtension on List<LocalLink> {
  List<Link> toLinkList() => map((l) => l.toLink()).toList();
}
