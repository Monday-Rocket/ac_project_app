import 'package:ac_project_app/models/folder/folder.dart';
import 'package:ac_project_app/models/link/link.dart';

class FeedData {

  FeedData({required this.folders, required this.links});

  List<Folder> folders;
  List<Link> links;
}
