import 'package:ac_project_app/models/link/link.dart';

class EditState {
  EditState(this.type, {this.link});

  final EditStateType type;
  final Link? link;

  EditState copyWith({EditStateType? type, Link? link}) {
    return EditState(
      type ?? this.type,
      link: link ?? this.link,
    );
  }
}

enum EditStateType { edit, view, editedView }
