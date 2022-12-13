import 'package:flutter/widgets.dart';

Map<String, dynamic> getArguments(BuildContext context) {
  return ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ??
      {};
}
