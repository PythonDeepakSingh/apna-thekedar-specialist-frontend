// lib/reviews_feedback_progress/screens/update_message_screen.dart
import 'package:flutter/material.dart';

class UpdateMessageScreen extends StatefulWidget {
  final String initialText;
  const UpdateMessageScreen({super.key, this.initialText = ''});

  @override
  State<UpdateMessageScreen> createState() => _UpdateMessageScreenState();
}

class _UpdateMessageScreenState extends State<UpdateMessageScreen> {
  late final TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Message'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              // Save button dabane par text ko pichli screen par wapas bhejein
              Navigator.pop(context, _messageController.text);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextFormField(
          controller: _messageController,
          autofocus: true,
          maxLines: null, // Taaki user kitna bhi lamba message likh sake
          expands: true, // Poori screen cover karega
          decoration: const InputDecoration(
            hintText: 'Write your project update here...',
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}