import 'package:book_media_teacher/pages/editor_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'services/supabase_service.dart';
import 'blocs/editor/editor_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const String supabaseUrl = 'https://cwycaaumvuexhqkcwwyl.supabase.co';
  const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImN3eWNhYXVtdnVleGhxa2N3d3lsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU0NDI5NjIsImV4cCI6MjA4MTAxODk2Mn0.3dM40yVwmgmZ-FTBFmB90hmzQpfErFS_Te-BiDo4Yno';
  try {
    await SupabaseService().init(url: supabaseUrl, anonKey: supabaseAnonKey);
  } catch (e) {
    print('Supabase init error: $e');
  }
  final editorBloc = EditorBloc();
  runApp(
    BlocProvider<EditorBloc>(create: (_) => editorBloc, child: const MyApp()),
  );
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Book Editor',
      theme: ThemeData(useMaterial3: true),
      home: const EditorPage(),
    );
  }
}