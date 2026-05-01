import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai_service.dart';

/// 🔹 Provider untuk AI Service
final aiServiceProvider = Provider<AIService>((ref) {
  return AIService();
});