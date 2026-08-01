import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// Override #12 — static, no shimmer/pulse. Ported intent from
/// `../app/src/components/ui/skeleton.tsx`: pulsing blocks read as unfinished.
class Skeleton extends StatelessWidget {
  final double width;
  final double height;
  final double radius;

  const Skeleton({super.key, this.width = double.infinity, this.height = 16, this.radius = AppRadius.md});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: AppColors.muted, borderRadius: BorderRadius.circular(radius)),
    );
  }
}
