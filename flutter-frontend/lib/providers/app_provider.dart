import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/user_profile.dart';
import '../services/api_service.dart';

enum AppStep { welcome, profile, chat }

class AppProvider extends ChangeNotifier {
  AppStep _step = AppStep.welcome;
  UserProfile _profile = const UserProfile();
  final List<ChatMessage> _messages = [];
  bool _streaming = false;
  String? _error;
  bool _backendOnline = false;

  AppStep get step => _step;
  UserProfile get profile => _profile;
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get streaming => _streaming;
  String? get error => _error;
  bool get backendOnline => _backendOnline;

  void setStep(AppStep step) {
    _step = step;
    notifyListeners();
  }

  void updateProfile(UserProfile profile) {
    _profile = profile;
    notifyListeners();
  }

  Future<void> checkBackend() async {
    _backendOnline = await ApiService.healthCheck();
    notifyListeners();
  }

  void clearMessages() {
    _messages.clear();
    _error = null;
    notifyListeners();
  }

  /// Build the profile JSON block message and immediately trigger AI response
  void submitProfile() {
    final content =
        'Generate my personalised 7-day nutrition and fitness plan based on my profile:\n\n'
        '```json\n${const JsonEncoder.withIndent('  ').convert(_profile.toJson())}\n```';

    _messages.add(ChatMessage(role: MessageRole.user, content: content));
    _error = null;
    notifyListeners();
    _triggerStream();
  }

  void sendUserMessage(String text) {
    if (text.trim().isEmpty || _streaming) return;
    _messages.add(ChatMessage(role: MessageRole.user, content: text.trim()));
    _error = null;
    notifyListeners();
    _triggerStream();
  }

  void _triggerStream() {
    _streaming = true;

    // Add empty assistant message that we'll fill in with tokens
    final assistantMsg =
        ChatMessage(role: MessageRole.assistant, content: '');
    _messages.add(assistantMsg);
    notifyListeners();

    final apiMessages = _messages
        .sublist(0, _messages.length - 1) // exclude the empty assistant msg
        .map((m) => m.toApiMessage())
        .toList();

    ApiService.streamChatCompletion(
      messages: apiMessages,
      onToken: (token) {
        final idx = _messages.length - 1;
        _messages[idx] =
            _messages[idx].copyWith(content: _messages[idx].content + token);
        notifyListeners();
      },
      onDone: () {
        _streaming = false;
        notifyListeners();
      },
      onError: (err) {
        _streaming = false;
        _error = err;
        // Remove the empty assistant message
        if (_messages.isNotEmpty &&
            _messages.last.role == MessageRole.assistant &&
            _messages.last.content.isEmpty) {
          _messages.removeLast();
        }
        notifyListeners();
      },
    );
  }
}
