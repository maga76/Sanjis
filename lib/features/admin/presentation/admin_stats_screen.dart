import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/widgets/state_views.dart';

/// Статистика (админ). Заглушка этапа 1. Пока здесь показан
/// скелетон загрузки — так будут выглядеть все экраны при загрузке.
class AdminStatsScreen extends StatelessWidget {
  const AdminStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.statistics)),
      body: const LoadingSkeleton(),
    );
  }
}
