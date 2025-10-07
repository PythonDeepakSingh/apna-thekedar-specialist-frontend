import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

// Yeh class hum data pass karne ke liye istemaal karenge
class ChecklistItemData {
  String taskName;
  TextEditingController controller;

  ChecklistItemData({required this.taskName})
      : controller = TextEditingController(text: taskName);
}

class PhaseItemEditScreen extends StatefulWidget {
  final List<String> initialItems;
  final int phaseNumber;

  const PhaseItemEditScreen({
    super.key,
    required this.initialItems,
    required this.phaseNumber,
  });

  @override
  _PhaseItemEditScreenState createState() => _PhaseItemEditScreenState();
}

class _PhaseItemEditScreenState extends State<PhaseItemEditScreen> {
  late List<ChecklistItemData> _items;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _items = widget.initialItems
        .map((task) => ChecklistItemData(taskName: task))
        .toList();
    if (_items.isEmpty) {
      _items.add(ChecklistItemData(taskName: ''));
    }
  }

  void _addItem() {
    setState(() {
      _items.add(ChecklistItemData(taskName: ''));
    });
    // Thoda delay dekar neeche scroll karein taaki naya item dikhe
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _saveAndGoBack() {
    // Controller se data ko update karein
    for (var item in _items) {
      item.taskName = item.controller.text;
    }
    
    // Sirf non-empty items ko waapis bhejein
    final updatedTasks = _items
        .map((item) => item.taskName.trim())
        .where((task) => task.isNotEmpty)
        .toList();
        
    Navigator.of(context).pop(updatedTasks);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Phase ${widget.phaseNumber} Items'),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.add),
            tooltip: 'Add New Item',
            onPressed: _addItem,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    children: [
                      Text('${index + 1}.', style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _items[index].controller,
                          decoration: const InputDecoration(
                            hintText: 'Enter task name...',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12),
                          ),
                          onChanged: (value) {
                             _items[index].taskName = value;
                          },
                        ),
                      ),
                      if (_items.length > 1)
                        IconButton(
                          icon: const Icon(Iconsax.trash, color: Colors.red),
                          onPressed: () => _removeItem(index),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Iconsax.save_2),
              label: const Text('Save Checklist'),
              onPressed: _saveAndGoBack,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (var item in _items) {
      item.controller.dispose();
    }
    super.dispose();
  }
}