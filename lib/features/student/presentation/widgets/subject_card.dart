import 'package:flutter/material.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/utils/subject_style.dart';
import '../../../../data/models/subject.dart';

/// Предмет в виде обложки школьной тетради: цветная обложка,
/// корешок слева и белая наклейка с названием предмета.
class SubjectCard extends StatelessWidget {
  const SubjectCard({super.key, required this.subject, required this.onTap});

  final Subject subject;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final base = parseHexColor(subject.color);
    final cover = isDark ? Color.lerp(base, Colors.black, 0.18)! : base;
    final spine = Color.lerp(cover, Colors.black, 0.28)!;
    final name = context.pickLang(subject.nameTg, subject.nameRu);

    // Тетрадь: корешок слева скруглён меньше, обрез справа — больше
    const shape = BorderRadius.only(
      topLeft: Radius.circular(6),
      bottomLeft: Radius.circular(6),
      topRight: Radius.circular(16),
      bottomRight: Radius.circular(16),
    );

    return Semantics(
      button: true,
      label: name,
      child: Material(
        color: cover,
        borderRadius: shape,
        elevation: 2,
        shadowColor: spine.withValues(alpha: 0.5),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.white.withValues(alpha: 0.2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Корешок
              Container(width: 10, color: spine),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: Icon(
                          subjectIcon(subject.icon),
                          color: Colors.white.withValues(alpha: 0.9),
                          size: 30,
                        ),
                      ),
                      const Spacer(),
                      _Label(name: name, ink: spine),
                      const SizedBox(height: 10),
                      Text(
                        context.l10n.gradeRange(
                          subject.minGrade,
                          subject.maxGrade,
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Белая наклейка на обложке: название предмета и строчка «для имени».
class _Label extends StatelessWidget {
  const _Label({required this.name, required this.ink});

  final String name;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: const Color(0xFF1A1D21),
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Container(height: 1.5, color: ink.withValues(alpha: 0.25)),
        ],
      ),
    );
  }
}
