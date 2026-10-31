import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:viora/firebase_options.dart';
import 'package:viora/screens/landingpage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const LandingPage());
}
