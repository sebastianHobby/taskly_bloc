import 'package:taskly_bloc/bootstrap.dart';
import 'package:taskly_bloc/presentation/features/app/app.dart';

Future<void> main() async {
  await bootstrap(() => const App());
}
