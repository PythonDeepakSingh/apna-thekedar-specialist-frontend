// lib/chat/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:apna_thekedar_specialist/api/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:iconsax/iconsax.dart';

// Message ko represent karne ke liye ek choti si class
class ChatMessage {
  final String sender;
  final String message;
  final bool isMe;

  ChatMessage({required this.sender, required this.message, required this.isMe});
}

class ChatScreen extends StatefulWidget {
  final int projectId;
  // Ab hum customer ka naam yahan lenge
  final String customerName;
  // Specialist ka apna naam, taaki pata chale kaun message bhej raha hai
  final String myName;

  const ChatScreen({
    super.key,
    required this.projectId,
    required this.customerName,
    required this.myName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  WebSocketChannel? _channel;
  bool _isLoading = true;
  String? _error;
  List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    // Ab hum pehle purane messages load karenge,
    // jisse token apne aap refresh ho jaayega.
    _loadOldMessages();
  }

  // WebSocket se connect karne ka function
  Future<void> _connectToChat() async {
    // Is function ka kaam ab bas connect karna hai,
    // token refresh ka kaam _loadOldMessages ne pehle hi kar diya hai.
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');

      if (accessToken == null) {
        throw Exception("Authentication token not found.");
      }
      
      final wsUrl = 'wss://apna-thekedar-backend.onrender.com/ws/chat/${widget.projectId}/?token=$accessToken';
      
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      _channel!.stream.listen((data) {
        final messageData = json.decode(data);
        final message = ChatMessage(
          sender: messageData['sender'],
          message: messageData['message'],
          isMe: messageData['sender'] == widget.myName,
        );
        if (mounted) {
          setState(() {
            _messages.insert(0, message);
          });
        }
      },
      onError: (error) {
        if(mounted) setState(() => _error = "Connection error. Please restart the page.");
      },
      onDone: () {
        if(mounted) setState(() => _error = "Connection closed. Please restart the page.");
      }
      );
    } catch (e) {
      if(mounted) setState(() => _error = "Failed to connect: $e");
    }
  }

  Future<void> _loadOldMessages() async {
    try {
      final apiService = ApiService();
      // YEH API CALL TOKEN KO REFRESH KAR DEGI AGAR ZAROORAT HUI
      final response = await apiService.get('/chat/projects/${widget.projectId}/messages/');
      
      if (mounted && response.statusCode == 200) {
        final List<dynamic> oldMessages = json.decode(response.body);
        setState(() {
          _messages = oldMessages.map((msg) => ChatMessage(
            sender: msg['sender_name'],
            message: msg['message'],
            isMe: msg['sender_name'] == widget.myName
          )).toList().reversed.toList();
          _isLoading = false;
        });

        // MESSAGES LOAD HONE KE BAAD HI CHAT SE CONNECT KAREIN
        _connectToChat();

      } else {
        if (mounted) setState(() { _isLoading = false; _error = "Could not load history"; });
      }
    } catch (e) {
      if(mounted) setState(() { _error = "Could not load history: $e"; _isLoading = false; });
    }
  }

  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      _channel?.sink.add(json.encode({'message': _controller.text}));
      _controller.clear();
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ${widget.customerName}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(8.0),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          return _buildMessageBubble(msg);
                        },
                      ),
          ),
          _buildMessageComposer(),
        ],
      ),
    );
  }
  
  Widget _buildMessageBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: msg.isMe ? Theme.of(context).primaryColor : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
             Text(
              msg.sender,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: msg.isMe ? Colors.white70 : Colors.black54
              ),
            ),
            const SizedBox(height: 4),
            Text(
              msg.message,
              style: TextStyle(color: msg.isMe ? Colors.white : Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageComposer() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Enter message...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Iconsax.send_1, color: Theme.of(context).primaryColor),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}

