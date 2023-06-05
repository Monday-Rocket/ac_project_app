enum ReportType {
  post('POST', ' 게시글을 신고하는'),
  user('LINK', '을 신고하는');

  const ReportType(this.name, this.subText);

  final String name;
  final String subText;
}
