enum FolderVisibleState { visible, invisible }

extension FolderVisibleStateExtension on FolderVisibleState {
  FolderVisibleState toggle() {
    if (this == FolderVisibleState.visible) {
      return FolderVisibleState.invisible;
    } else {
      return FolderVisibleState.visible;
    }
  }
}
