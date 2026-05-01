import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIService {
  String get apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  Future<String> sendMessage(String message, {String? userContext}) async {
    print("API KEY => $apiKey"); // DEBUG

    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=$apiKey",
    );

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "text": """
Kamu adalah AI Habit Coach dalam aplikasi Habit Tracker.

Konteks aplikasi:
- Aplikasi untuk membantu user membangun kebiasaan
- User bisa membuat habit, melihat progress, statistik, dan pencapaian
- Fokus: disiplin, konsistensi, produktivitas

Tugas kamu:
- Jawab seperti coach pribadi
- Berikan solusi praktis (langsung bisa dilakukan)
- Gunakan bahasa santai tapi tegas
- Jangan terlalu panjang

Aturan:
- Fokus hanya pada habit dan produktivitas
- Jangan menjawab di luar konteks
- Berikan langkah konkret

Data user:
${userContext ?? "Belum ada data user"}

Pertanyaan user:
$message
"""
              }
            ]
          }
        ]
      }),
    );

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      try {
        return data['candidates'][0]['content']['parts'][0]['text'];
      } catch (e) {
        return "AI tidak memberikan respon valid.";
      }
    } else {
      return "Error API: ${response.statusCode}";
    }
  }
}