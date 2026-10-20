import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Шапка в виде листа школьной тетради: синий лист «в клетку»
/// и золотая линия полей слева. Заходит под статус-бар.
class NotebookHeader extends StatelessWidget {
  const NotebookHeader({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 24),
    this.rounded = true,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool rounded;

  /// Цвет «листа» — школьные синие чернила.
  static Color color(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF173663)
      : const Color(0xFF1E5AA8);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: color(context),
          borderRadius: rounded
              ? const BorderRadius.vertical(bottom: Radius.circular(24))
              : null,
        ),
        child: NotebookPaper(
          child: SafeArea(
            bottom: false,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

/// Сетка «в клетку» и линия полей поверх любого фона.
class NotebookPaper extends StatelessWidget {
  const NotebookPaper({super.key, required this.child, this.marginLine = true});

  final Widget child;
  final bool marginLine;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GridPaper(
            color: Colors.white.withValues(alpha: 0.09),
            interval: 22,
            divisions: 1,
            subdivisions: 1,
            child: const SizedBox.expand(),
          ),
        ),
        if (marginLine)
          Positioned(
            top: 0,
            bottom: 0,
            right: 28,
            child: Container(
              width: 2,
              color: const Color(0xFFF2A900).withValues(alpha: 0.55),
            ),
          ),
        child,
      ],
    );
  }
}
