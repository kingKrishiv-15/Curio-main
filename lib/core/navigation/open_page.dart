import 'package:flutter/material.dart';

Future<T?> openPage<T>(BuildContext context, Widget page) {
  return Navigator.of(
    context,
  ).push<T>(MaterialPageRoute<T>(builder: (_) => page));
}
