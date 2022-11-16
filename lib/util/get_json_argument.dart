import 'package:flutter/material.dart';

Map<String, dynamic> getJsonArgument(BuildContext context) {
  return ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ??
      {};
}
