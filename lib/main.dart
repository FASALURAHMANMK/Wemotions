import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'package:Wemotions/features/homescreen/video_provider.dart';

void main() {
  runApp(const WeMotionsApp());
}

class WeMotionsApp extends StatelessWidget {
  const WeMotionsApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Attach VideoProvider here
        ChangeNotifierProvider(create: (_) => VideoProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: Colors.black,
          primaryColor: Colors.purple,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}