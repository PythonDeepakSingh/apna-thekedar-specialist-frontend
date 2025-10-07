// lib/profile/screens/my_earnings_screen.dart (Nayi File)
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyEarningsScreen extends StatefulWidget {
  const MyEarningsScreen({super.key});

  @override
  State<MyEarningsScreen> createState() => _MyEarningsScreenState();
}

class _MyEarningsScreenState extends State<MyEarningsScreen> {
  WebViewController? _controller;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPage();
  }

  Future<void> _loadPage() async {
    try {
      // Step 1: Flutter se authentication token nikaalo
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');

      if (accessToken == null) {
        throw Exception("Authentication token not found. Please log in again.");
      }

      // Step 2: Backend URL taiyaar karo
      final url = Uri.parse(
        'https://apna-thekedar-backend.onrender.com/api/v1/operations/my-earnings-webview/?token=$accessToken'
      );

      // Step 3: WebView Controller ko set karo
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) {
              if (mounted) setState(() => _isLoading = false);
            },
            onWebResourceError: (WebResourceError error) {
              if (mounted) setState(() => _error = "Failed to load page: ${error.description}");
            },
          ),
        )
        ..loadRequest(url);
        
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
    
    if (mounted) setState(() {});
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Earnings'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_error!)));
    }

    if (_controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        WebViewWidget(controller: _controller!),
        if (_isLoading)
          const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}