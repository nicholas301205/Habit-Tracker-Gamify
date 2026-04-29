import 'package:flutter/material.dart';

class LevelUpDialog extends StatefulWidget {
  final int newLevel;
  final String levelTitle;
  const LevelUpDialog({
    super.key,
    required this.newLevel,
    required this.levelTitle,
  });

  static Future<void> show(
    BuildContext context, {
    required int newLevel,
    required String levelTitle,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => LevelUpDialog(
        newLevel: newLevel,
        levelTitle: levelTitle,
      ),
    );
  }

  @override
  State<LevelUpDialog> createState() => _LevelUpDialogState();
}

class _LevelUpDialogState extends State<LevelUpDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.amber.shade600,
                  Colors.orange.shade700,
                ],
              ),

              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 4,
                ),
              ],
            ),

            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🎉', style: TextStyle(fontSize: 52)),
                const SizedBox(height: 8),
                const Text(
                  'LEVEL UP!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),

                  child: Text(
                    'Level ${widget.newLevel}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 8),
                Text(
                  widget.levelTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                  ),
                ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.orange.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),

                    child: const Text('Keep Going!',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}