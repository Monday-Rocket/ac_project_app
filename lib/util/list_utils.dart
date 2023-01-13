extension CheckContains on List<String?> {
  bool checkContains(String? compare) {
    if (contains(compare ?? '')) {
      return true;
    } else {
      return false;
    }
  }
}