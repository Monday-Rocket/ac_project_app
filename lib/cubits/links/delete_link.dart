import 'package:ac_project_app/models/link/link.dart';
import 'package:ac_project_app/provider/api/folders/link_api.dart';

class DeleteLink {
  static Future<bool> delete(Link link) async {
    return LinkApi().deleteLink(link);
  }
}
