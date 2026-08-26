import 'package:flutter/material.dart';
import 'package:missao_app/telas/login_tela.dart';

// Variável global que controla o tema. Começa lendo o padrão do sistema do celular.
final ValueNotifier<ThemeMode> temaGlobalNotifier = ValueNotifier(ThemeMode.system);

void main() {
  runApp(const MissaoApp());
}

class MissaoApp extends StatelessWidget {
  const MissaoApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder escuta as mudanças e recarrega o app instantaneamente
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: temaGlobalNotifier,
      builder: (context, modoAtual, child) {
        return MaterialApp(
          title: 'Preparação Missionária',
          debugShowCheckedModeBanner: false,
          themeMode: modoAtual, // Aplica o modo atual
          
          // TEMA CLARO
          theme: ThemeData(
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D47A1), brightness: Brightness.light),
            scaffoldBackgroundColor: Colors.grey.shade50,
            useMaterial3: true,
          ),
          
          // TEMA ESCURO
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0D47A1), brightness: Brightness.dark),
            scaffoldBackgroundColor: const Color(0xFF121212), // Fundo principal escuro
            useMaterial3: true,
          ),
          
          home: const LoginPage(),
        );
      },
    );
  }
}