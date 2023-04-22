import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

InkWell InkWellButton(Key key) =>
    find.byKey(key).evaluate().first.widget as InkWell;

GestureDetector GestureDetectorButton(Key key) =>
    find.byKey(key).evaluate().first.widget as GestureDetector;
