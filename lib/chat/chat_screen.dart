// lib/chat/chat_screen.dart (Updated with Error Handling)
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:apna_thekedar_specialist/api/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:iconsax/iconsax.dart';

// === Naye Imports ===
import 'dart:io';
import 'package:apna_thekedar_specialist/core/widgets/attractive_error_widget.dart';

// Message ko represent karne ke liye ek choti si class
class ChatMessage {
  final String sender;
  final String message;
  final bool isMe;

  ChatMessage({required this.sender, required this.message, required this.isMe});
}

class ChatScreen extends StatefulWidget {
  final int projectId;
  final String customerName;
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
  String? _error; // Isko ab _errorType se manage karenge
  String? _errorType; // === Naya Variable ===
  List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadOldMessages();
  }

  // === Is function ko update kiya gaya hai ===
  Future<void> _loadOldMessages() async {
    setState(() {
      _isLoading = true;
      _errorType = null;
      _error = null;
    });

    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        throw 'no_internet';
      }

      final apiService = ApiService();
      final response = await apiService.get('/chat/projects/${widget.projectId}/messages/');
      
      if (mounted) {
        if (response.statusCode == 200) {
          final List<dynamic> oldMessages = json.decode(response.body);
          setState(() {
            _messages = oldMessages.map((msg) => ChatMessage(
              sender: msg['sender_name'],
              message: msg['message'],
              isMe: msg['sender_name'] == widget.myName
            )).toList().reversed.toList();
          });
          // Messages load hone ke baad hi chat se connect karein
          await _connectToChat();
        } else {
          throw 'server_error';
        }
      }
    } on SocketException catch (_) {
      _errorType = 'no_internet';
    } catch (e) {
      if (mounted) {
        _errorType = e.toString() == 'server_error' ? 'server_error' : 'unknown';
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // === Is function ko bhi update kiya gaya hai ===
  Future<void> _connectToChat() async {
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
        if(mounted) setState(() => _error = "Connection error. Please try again.");
      },
      onDone: () {
        if(mounted) setState(() => _error = "Connection closed. Please restart the page.");
      }
      );
    } catch (e) {
      if(mounted) setState(() => _error = "Failed to connect: $e");
    }
  }

  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      if (_channel == null || _channel?.closeCode != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Not connected. Cannot send message.')),
        );
        return;
      }
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
            child: _buildBody(),
          ),
          // Ab yeh condition ke saath chalega
          if (!_isLoading && _errorType == null)
            _buildMessageComposer(),
        ],
      ),
    );
  }

  // === Yeh naya function hai UI ko manage karne ke liye ===
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorType != null) {
      return AttractiveErrorWidget(
        imagePath: _errorType == 'no_internet' ? 'assets/no_internet.png' : 'assets/server_error.png',
        title: _errorType == 'no_internet' ? "No Internet" : "Server Error",
        message: "We couldn't load the chat history. Please check your connection and try again.",
        buttonText: "Retry",
        onRetry: _loadOldMessages,
      );
    }
    
    // Purana UI jab sab kuch theek ho
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.all(8.0),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        return _buildMessageBubble(msg);
      },
    );
  }
  
  // ... (baki ke functions _buildMessageBubble aur _buildMessageComposer waise hi rahenge) ...
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
    // WebSocket ke connection error ko yahan dikhayenge
    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        color: Colors.red.shade100,
        child: Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: Colors.red.shade900)),
      );
    }
    
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