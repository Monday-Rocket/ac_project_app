String? _checkClipboardLink = '';

bool isClipboardLink(String? text) {
  if (text == null || text.isEmpty) return false;
  return text == _checkClipboardLink;
}

void setClipboardLink(String? text) {
  _checkClipboardLink = text;
}
