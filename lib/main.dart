import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; 
import 'package:missao_app/telas/login_tela.dart';

final ValueNotifier<ThemeMode> temaGlobalNotifier = ValueNotifier(ThemeMode.system);

void main() async {
  // Garante que o Flutter esteja pronto antes de chamar o Firebase
  WidgetsFlutterBinding.ensureInitialized();
  
  // Liga o motor do Firebase usando as configurações geradas pelo CLI
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MissaoApp());
}

class MissaoApp extends StatelessWidget {
  const MissaoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: temaGlobalNotifier,
      builder: (context, modoAtual, child) {
        return MaterialApp(
          title: 'Prepara o Missionário',
          debugShowCheckedModeBanner: false,
          themeMode: modoAtual,
          theme: ThemeData(
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D47A1), brightness: Brightness.light),
            scaffoldBackgroundColor: Colors.grey.shade50,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D47A1), brightness: Brightness.dark),
            scaffoldBackgroundColor: const Color(0xFF121212),
            useMaterial3: true,
          ),
          home: const LoginPage(),
        );
      },
    );
  }
}