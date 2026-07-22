import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:neuroup/app/app.dart';
import 'package:neuroup/app/bootstrap.dart';

void main() => bootstrap(() => const ProviderScope(child: NeuroupApp()));
