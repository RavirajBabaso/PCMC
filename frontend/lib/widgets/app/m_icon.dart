import 'package:flutter/material.dart';

/// Universal Icon Wrapper
/// Works with:
/// - Material Icons (Icons.*)
/// - Iconsax (Iconsax.*)
/// - FontAwesome / any IconData
///
/// Fixes:
/// - Material font issues on mobile
/// - Iconsax compatibility
/// - Removes hardcoded font dependency
class MIcon extends StatelessWidget {
  const MIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
  });

  final IconData icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);

    return Icon(
      icon,
      size: size ?? iconTheme.size ?? 24,
      color: color ?? iconTheme.color,
      semanticLabel: semanticLabel,
    );
  }
}