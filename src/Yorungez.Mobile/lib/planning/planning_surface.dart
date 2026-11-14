import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'planning_time.dart';

class PlanningSurface extends StatelessWidget {
  const PlanningSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.highlighted = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding, margin;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).colorScheme;
    final ink = palette.primary;
    return Card(
      margin: margin,
      color: Color.alphaBlend(
        (highlighted ? palette.secondary : palette.surface).withValues(
          alpha: highlighted ? .23 : .32,
        ),
        const Color(0xFF202124),
      ),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: ink.withValues(alpha: highlighted ? .42 : .25)),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class PlanningEventHeading extends StatelessWidget {
  const PlanningEventHeading({
    super.key,
    required this.instant,
    required this.zone,
    required this.title,
    this.subtitle,
  });

  final DateTime instant;
  final String zone, title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final local = PlanningTime.local(instant, zone);
    final ink = theme.colorScheme.primary;
    return Row(
      children: [
        ExcludeSemantics(
          child: Container(
            constraints: const BoxConstraints(minWidth: 54),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(
              color: ink.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat.d(language).format(local),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: ink,
                    height: 1.1,
                  ),
                ),
                Text(
                  DateFormat.MMM(language).format(local),
                  style: theme.textTheme.labelSmall?.copyWith(color: ink),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              if (subtitle case final value?)
                Text(
                  value,
                  style: theme.textTheme.bodySmall?.copyWith(color: ink),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
