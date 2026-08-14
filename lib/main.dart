import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:url_launcher/url_launcher.dart';
import 'api_key.dart';

void main() => runApp(const JarvisApp());

class JarvisApp extends StatelessWidget {
  const JarvisApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    home: const ChatScreen(),
  );
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  late FlutterTts _tts;
  late stt.SpeechToText _stt;
  bool _isListening = false;
  String _mode = "Friendly"; // Mode setting

  final String _apiKey = groqApiKey;



  @override
  void initState() {
    super.initState();
    _stt = stt.SpeechToText();
    _tts = FlutterTts();
    _tts.setLanguage("hi-IN");
  }

  // System Commands Logic
  Future<void> _handleCommand(String query) async {
    final q = query.toLowerCase();
    if (q.contains("gallery")) {
      launchUrl(Uri.parse("content://media/internal/images/media"));
    } else if (q.contains("call")) {
      launchUrl(Uri.parse("tel:+91XXXXXXXXXX")); // Replace with number
    } else if (q.contains("whatsapp")) {
      launchUrl(Uri.parse("whatsapp://send?phone=+91XXXXXXXXXX"));
    } else if (q.contains("song") || q.contains("play")) {
      launchUrl(Uri.parse("https://youtube.com/results?search_query=$query"));
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text;
    if (text.isEmpty) return;

    // Jarvis Personality Logic
    String systemPrompt = "You are Jarvis, created by Shivam Boss. Always greet with 'Namaste Boss'. If asked who created you, say Shivam Boss. Respond in smooth Hinglish.";
    
    if (_mode == "Friendly") systemPrompt += " Be extra friendly and caring.";

    // Command Check
    await _handleCommand(text);

    setState(() => _messages.add({'sender': 'Shivam Boss', 'text': text}));
    _controller.clear();

    // Groq API Call
    final response = await http.post(
      Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
      headers: {'Authorization': 'Bearer $_apiKey', 'Content-Type': 'application/json'},
      body: jsonEncode({
        'model': 'llama-3.3-70b-versatile',
        'messages': [{'role': 'system', 'content': systemPrompt}, {'role': 'user', 'content': text}],
      }),
    );

    if (response.statusCode == 200) {
      final reply = jsonDecode(utf8.decode(response.bodyBytes))['choices'][0]['message']['content'];
      setState(() => _messages.add({'sender': 'JARVIS', 'text': reply}));
      await _tts.speak(reply);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("J.A.R.V.I.S. (Shivam Boss AI)")),
      body: Column(children: [
        Expanded(child: ListView.builder(itemCount: _messages.length, itemBuilder: (context, i) => ListTile(title: Text(_messages[i]['sender']!), subtitle: Text(_messages[i]['text']!)))),
        Row(children: [
          IconButton(icon: Icon(_isListening ? Icons.mic : Icons.mic_none), onPressed: () {}),
          Expanded(child: TextField(controller: _controller)),
          IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
        ])
      ]),
    );
  }
}
