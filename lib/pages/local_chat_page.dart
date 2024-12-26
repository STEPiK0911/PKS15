// lib/pages/local_chat_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/message.dart';

class LocalChatPage extends StatefulWidget {
  const LocalChatPage({Key? key}) : super(key: key);

  @override
  _LocalChatPageState createState() => _LocalChatPageState();
}

class _LocalChatPageState extends State<LocalChatPage> {
  final TextEditingController _controller = TextEditingController();
  final String user = 'alla@polo.ru';
  final String admin = 'admin@admin.ru';

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Локальный Чат'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              chatProvider.clearMessages();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: chatProvider.messages.length,
              itemBuilder: (context, index) {
                final message = chatProvider.messages[index];
                bool isUser = message.sender == user;
                return Align(
                  alignment:
                  isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    margin:
                    const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[100] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(message.content),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration:
                    const InputDecoration(hintText: 'Введите сообщение'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    if (_controller.text.trim().isEmpty) return;
                    final message = Message(
                      sender: user,
                      content: _controller.text.trim(),
                      timestamp: DateTime.now(),
                    );
                    chatProvider.addMessage(message);
                    _controller.clear();

                    // Автоматический ответ администратора
                    Future.delayed(const Duration(seconds: 1), () {
                      final adminMessage = Message(
                        sender: admin,
                        content: 'Принято, я свяжусь с вами.',
                        timestamp: DateTime.now(),
                      );
                      chatProvider.addMessage(adminMessage);
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
