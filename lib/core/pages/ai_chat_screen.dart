import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habbit_tracker_gamify/providers/ai_provider.dart';

class AIChatScreen extends ConsumerStatefulWidget {
  const AIChatScreen({super.key});

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final TextEditingController controller = TextEditingController();
  final List<Map<String, String>> messages = [];

  bool isLoading = false;

  Future<void> sendMessage() async {
    final text = controller.text.trim();
    if (text.isEmpty || isLoading) return;

    setState(() {
      messages.add({"role": "user", "text": text});
      isLoading = true;
    });

    controller.clear();

    try {
      final ai = ref.read(aiServiceProvider);
      final reply = await ai.sendMessage(text);

      setState(() {
        messages.add({"role": "ai", "text": reply});
      });
    } catch (e) {
      setState(() {
        messages.add({
          "role": "ai",
          "text": "Terjadi error, coba lagi nanti."
        });
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildMessage(Map<String, String> msg) {
    final isUser = msg["role"] == "user";

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser
              ? Colors.blue
              : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          msg["text"]!,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Habit Coach"),
      ),
      body: Column(
        children: [
          /// CHAT LIST
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 10),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return buildMessage(messages[index]);
              },
            ),
          ),

          /// LOADING
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text("AI sedang mengetik..."),
            ),

          /// INPUT
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        hintText: "Tanya AI...",
                      ),
                      onSubmitted: (_) => sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}