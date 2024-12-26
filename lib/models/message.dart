// lib/models/message.dart
class Message {
  final String sender;
  final String content;
  final DateTime timestamp;

  Message({
    required this.sender,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'sender': sender,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      sender: map['sender'],
      content: map['content'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
