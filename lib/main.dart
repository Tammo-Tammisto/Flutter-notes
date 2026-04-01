import 'package:flutter/material.dart';
import 'package:flutter_notes/screens/dashboard_screen.dart';
import 'package:flutter_notes/screens/main_layout.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

void main() {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Notes App",
      theme: ThemeData(
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: AppBarTheme(color: Colors.black87),
      ),
      home: const MainLayout(),
    );
  }
}
