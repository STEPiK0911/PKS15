// lib/providers/chat_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message.dart';

class ChatProvider extends ChangeNotifier {
  List<Message> _messages = [];
  List<Message> get messages => _messages;

  ChatProvider() {
    loadMessages();
  }

  Future<void> loadMessages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? messagesData = prefs.getString('messages');
    if (messagesData != null) {
      List<dynamic> decoded = jsonDecode(messagesData);
      _messages = decoded.map((e) => Message.fromMap(e)).toList();
      notifyListeners();
    }
  }

  Future<void> addMessage(Message message) async {
    _messages.add(message);
    notifyListeners();
    await saveMessages();
  }

  Future<void> saveMessages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> mapped = _messages.map((e) => e.toMap()).toList();
    prefs.setString('messages', jsonEncode(mapped));
  }

  void clearMessages() async {
    _messages.clear();
    notifyListeners();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('messages');
  }
}
