import 'package:flutter/material.dart';

import '../../../core/theme/haki_theme.dart';
import '../../../models/group_model.dart';

class GroupAvatar extends StatelessWidget {
  const GroupAvatar({super.key, required this.group, this.size = 52, this.radius});
  final GroupModel group;
  final double size;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius ?? size * 0.36),
        gradient: RadialGradient(
          center: const Alignment(0.4, -0.5),
          radius: 1.1,
          colors: HakiColors.auraFor(group.id + 3),
          stops: const [0, 0.5, 1],
        ),
      ),
      child: Text(group.initials, style: HakiText.display(size * 0.36, weight: FontWeight.w700)),
    );
  }
}
