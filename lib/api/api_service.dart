// lib/api/api_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:apna_thekedar_specialist/notifications/notification_model.dart';

class ApiService {
  final String _baseUrl = 'https://apna-thekedar-backend.onrender.com/api/v1';

  Future<http.Response> publicPost(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$_baseUrl$endpoint');
    return await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );
  }

  Future<Map<String, String?>> _getTokens() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'access': prefs.getString('accessToken'),
      'refresh': prefs.getString('refreshToken'),
    };
  }

  Future<String?> _refreshAccessToken() async {
    final tokens = await _getTokens();
    final refreshToken = tokens['refresh'];
    if (refreshToken == null) return null;

    final url = Uri.parse('$_baseUrl/auth/token/refresh/');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final newAccessToken = responseData['access'];
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('accessToken', newAccessToken);
        
        return newAccessToken;
      } else {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        return null;
      }
    } catch (e) {
      print("Error refreshing token: $e");
      return null;
    }
  }

  Future<http.Response> _makeRequest(
      Future<http.Response> Function(String accessToken) requestFunction) async {
    final tokens = await _getTokens();
    String? accessToken = tokens['access'];

    if (accessToken == null) {
      throw Exception('User not logged in');
    }

    var response = await requestFunction(accessToken);

    if (response.statusCode == 401) {
      final newAccessToken = await _refreshAccessToken();
      if (newAccessToken != null) {
        response = await requestFunction(newAccessToken);
      } else {
         throw Exception('Session expired. Please log in again.');
      }
    }
    return response;
  }

Future<http.Response> get(String endpoint) async {
  return _makeRequest((accessToken) async { // async yahan add karein
    final url = Uri.parse('$_baseUrl$endpoint');
    final response = await http.get( // await yahan add karein
      url,
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    // ================== YEH LINE ADD KAREIN ==================
    // Sirf project details wale response ko print karega
    if (endpoint.contains('/projects/') && endpoint.contains('/details')) {
      print('>>> RESPONSE FROM $endpoint: ${response.body}');
    }
    // =========================================================

    return response; // response ko return karein
  });
}


  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    return _makeRequest((accessToken) {
      final url = Uri.parse('$_baseUrl$endpoint');
      return http.post(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );
    });
  }
  
  // YEH ISKA ORIGINAL, SAHI VERSION HAI
  Future<http.Response> patch(String endpoint, Map<String, dynamic> data) async {
    return _makeRequest((accessToken) async {
      final url = Uri.parse('$_baseUrl$endpoint');
      return http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode(data),
      );
    });
  }

  Future<http.Response> _makeRequestWithFiles(
      Future<http.MultipartRequest> Function(String accessToken) requestFunction) async {
    final tokens = await _getTokens();
    String? accessToken = tokens['access'];

    if (accessToken == null) {
      throw Exception('User not logged in');
    }

    var request = await requestFunction(accessToken);
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 401) {
      final newAccessToken = await _refreshAccessToken();
      if (newAccessToken != null) {
        var newRequest = await requestFunction(newAccessToken);
        var newStreamedResponse = await newRequest.send();
        response = await http.Response.fromStream(newStreamedResponse);
      } else {
        throw Exception('Session expired. Please log in again.');
      }
    }
    return response;
  }
  
  Future<http.Response> patchWithFiles(
    String endpoint, {
    required Map<String, String> fields,
    required Map<String, File> files,
  }) async {
    return _makeRequestWithFiles((accessToken) async {
      final url = Uri.parse('$_baseUrl$endpoint');
      var request = http.MultipartRequest('PATCH', url);
      request.headers['Authorization'] = 'Bearer $accessToken';
      request.fields.addAll(fields);
      for (var entry in files.entries) {
        request.files.add(
          await http.MultipartFile.fromPath(entry.key, entry.value.path),
        );
      }
      return request;
    });
  }

  Future<http.Response> delete(String endpoint) async {
    return _makeRequest((accessToken) async {
      final url = Uri.parse('$_baseUrl$endpoint');
      return http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );
    });
  }

  Future<http.Response> postWithFiles(
    String endpoint, {
    required Map<String, String> fields,
    required Map<String, File> files,
  }) async {
    return _makeRequestWithFiles((accessToken) async {
      final url = Uri.parse('$_baseUrl$endpoint');
      var request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $accessToken';
      request.fields.addAll(fields);
      for (var entry in files.entries) {
        request.files.add(
          await http.MultipartFile.fromPath(entry.key, entry.value.path),
        );
      }
      return request;
    });
  }

  Future<http.Response> postWithFilesAndList({ // <-- Yahan se 'String s,' hata diya gaya hai
    required String endpoint,
    required Map<String, String> fields,
    required Map<String, List<File>> fileLists,
    required Map<String, List<String>> fieldLists,
  }) async {
    return _makeRequestWithFiles((accessToken) async {
      final url = Uri.parse('$_baseUrl$endpoint');
      var request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $accessToken';

      request.fields.addAll(fields);

      for (var entry in fieldLists.entries) {
        for (var value in entry.value) {
          request.fields[entry.key] = value;
        }
      }

      for (var entry in fileLists.entries) {
        for (var file in entry.value) {
          request.files.add(
            await http.MultipartFile.fromPath(entry.key, file.path),
          );
        }
      }
      return request;
    });
  }

  // === YEH NAYA FUNCTION ADD KAREIN ===
  Future<http.Response> postMultipart(
    String endpoint, {
    required Map<String, String> fields,
    required Map<String, List<File>> files,
    required Map<String, List<String>> fieldLists,
  }) async {
    return _makeRequestWithFiles((accessToken) async {
      final url = Uri.parse('$_baseUrl$endpoint');
      var request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $accessToken';
      
      request.fields.addAll(fields);

      // Handle list of fields (item_names)
      for (var entry in fieldLists.entries) {
        request.fields[entry.key] = json.encode(entry.value); // Encode as JSON string
      }

      // Handle list of files (images)
      for (var entry in files.entries) {
        for (var file in entry.value) {
          request.files.add(
            await http.MultipartFile.fromPath(entry.key, file.path),
          );
        }
      }
      return request;
    });
  }

  // --- NAYE FUNCTIONS YAHAN HAIN ---
  Future<List<NotificationModel>> getNotifications() async {
    final response = await get('/notifications/');
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => NotificationModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load notifications');
    }
  }

  Future<void> markNotificationAsRead(List<int> notificationIds) async {
    await post(
      '/notifications/mark-as-read/',
      {'notification_ids': notificationIds},
    );
  }

    Future<http.Response> createSupportRequest(int projectId, String problem) {
    return post(
      '/support/projects/$projectId/request-support/',
      {
        'problem': problem,
      },
    );
  }
  Future<http.Response> checkForUpdate(String versionCode, String deviceType) {
    // Yahan hum seedha 'get' ka istemaal kar sakte hain
    return get('/operations/check-for-update/?version_code=$versionCode&device_type=$deviceType');
  }
}
