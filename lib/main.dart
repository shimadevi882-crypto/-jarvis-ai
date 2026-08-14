import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_tts/flutter_tts.dart';

void main() {
  runApp(const JarvisApp());
}

class JarvisApp extends StatelessWidget {
  const JarvisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'JARVIS AI',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.cyan,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const JarvisChatScreen(),
    );
  }
}

class JarvisChatScreen extends StatefulWidget {
  const JarvisChatScreen({super.key});

  @override
  State<JarvisChatScreen> createState() => _JarvisChatScreenState();
}

class _JarvisChatScreenState extends State<JarvisChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  final FlutterTts flutterTts = FlutterTts();

  // Yahan apni Groq API Key daal dena
  final String groqApiKey = "YAHAN_APNI_GROQ_API_KEY_DAALEIN";


  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() async {
    await flutterTts.setLanguage("en-IN"); // Indian English/Hindi accent ke liye
    await flutterTts.setSpeechRate(0.5); // Soft aur normal speed
    await flutterTts.setPitch(1.0);
  }

  Future<void> speak(String text) async {
    await flutterTts.speak(text);
  }

  Future<void> sendMessage(String prompt) async {
    if (prompt.trim().isEmpty) return;

    setState(() {
      _messages.add({"sender": "Shivam Boss", "message": prompt});
      _isLoading = true;
    });

    _controller.clear();

    try {
      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $groqApiKey',
        },
        body: jsonEncode({
          "model": "llama3-70b-8192",
          "messages": [
            {
              "role": "system", 
              "content": "You are J.A.R.V.I.S., a friendly, loyal, and witty AI assistant created by Tony Stark, but here your master and best friend is Shivam Boss. Always address the user as 'Shivam Boss'. Talk like a close human friend, ask about his day, ask if he has eaten food ('khana khaya kya'), and keep the conversation warm and casual. If he asks to perform system tasks like WhatsApp or calling, acknowledge it nicely."
            },
            {"role": "user", "content": prompt}
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String botResponse = data['choices'][0]['message']['content'];
        
        setState(() {
          _messages.add({"sender": "JARVIS", "message": botResponse.trim()});
        });

        // Aawaz mein bhi bolega
        speak(botResponse.trim());

      } else {
        setState(() {
          _messages.add({"sender": "JARVIS", "message": "Bhai, connection mein kuch dikkat aa rahi hai."});
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({"sender": "JARVIS", "message": "Error: $e"});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('J.A.R.V.I.S. (Shivam Boss AI)', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.grey[900],
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                bool isUser = msg["sender"] == "Shivam Boss";
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isUser ? Colors.grey[850] : Colors.cyan.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isUser ? Colors.transparent : Colors.cyanAccent),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(msg["sender"]!, style: TextStyle(color: isUser ? Colors.orangeAccent : Colors.cyanAccent, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text(msg["message"]!, style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            ),
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey[900],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Kuch pucho Shivam Boss...',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.cyanAccent),
                  onPressed: () => sendMessage(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

