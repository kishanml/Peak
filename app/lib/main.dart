import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'loading_page.dart';
import 'theme/peak_colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const PeakApp());
}

class PeakApp extends StatelessWidget {
  const PeakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Peak',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: PeakColors.baseBg,
      ),
      home: const SplashScreen(),
    );
  }
}
