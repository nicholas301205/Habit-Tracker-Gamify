import 'package:flutter/material.dart';

class AnimatedXpBar extends StatefulWidget {
  final double progress;  // 0.0 – 1.0
  final int xp;
  final int level;
  final int xpToNext;

  const AnimatedXpBar({
    super.key,
    required this.progress,
    required this.xp,
    required this.level,
    required this.xpToNext,
  });

  @override
  State<AnimatedXpBar> createState() => _AnimatedXpBarState();
}

class _AnimatedXpBarState extends State<AnimatedXpBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  double _oldProgress = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _anim = Tween(begin: 0.0, end: widget.progress).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();
    _oldProgress = widget.progress;
  }

  @override
  void didUpdateWidget(AnimatedXpBar old) {
    super.didUpdateWidget(old);
    if (old.progress != widget.progress) {
      _anim = Tween(
        begin: _oldProgress,
        end: widget.progress,
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
      _ctrl.forward(from: 0);
      _oldProgress = widget.progress;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${widget.xp} XP',
              style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500,
              ),
            ),
            Text('${widget.xpToNext} XP lagi ke Level ${widget.level + 1}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 6),
        AnimatedBuilder(
          animation: _anim,
          builder: (_, __) => ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _anim.value,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
            ),
          ),
        ),
      ],
    );
  }
}

// Pemakaian di home_dashboard.dart — ganti LinearProgressIndicator lama:
// AnimatedXpBar(
//   progress: user.xpProgress,
//   xp: user.xp,
//   level: user.currentLevel,
//   xpToNext: user.xpToNextLevel,
// )