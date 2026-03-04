import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:bonding_app/APIService/Remote/AppException.dart';
import 'package:bonding_app/APIService/Remote/network/BaseApiService.dart'
    show BaseApiService;
import 'package:bonding_app/BondingScreens/AuthService.dart';
import 'package:bonding_app/Bonding_Utils/AppLogger/app_logger.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart' as http_parser;
import 'package:mime/mime.dart';
// import 'package:prod/APIService/Remote/AppException.dart';

void _debugLog(Object? message) {
  if (kDebugMode) {
    debugPrint(message?.toString() ?? 'null');
  }
}

class NetworkApiService extends BaseApiService {
  @override
  Future getResponse(String url) async {
    _debugLog("efcdececdecc");
    // final String? token = await AuthService.getToken();
    dynamic responseJson;
    Map<String, String> headers = {"Authorization": "Bearer "}; // add token
    try {
      _debugLog("evceadcc");
      final response = await http.get(
        Uri.parse(baseUrl + url),
        headers: headers,
      );
      _debugLog("??>>?>?>?>$response");
      responseJson = returnResponse(response);
      _debugLog("????????$responseJson");
      _debugLog("////////////${baseUrl + url}");
    } on SocketException {
      throw FetchDataException('No Internet Connection');
    }
    return responseJson;
  }

  Future getResponseV3(String url) async {
    _debugLog("efcdececdecc");

    dynamic responseJson;
    // add token
    try {
      _debugLog("evceadcc");
      final response = await http.get(Uri.parse(url));
      _debugLog("??>>?>?>?>$response");
      responseJson = returnResponse(response);
      _debugLog("????????$responseJson");
      _debugLog("////////////${url}");
    } on SocketException {
      throw FetchDataException('No Internet Connection');
    }
    return responseJson;
  }

  Future<Map<String, dynamic>> getResponseV2(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.parse(
      baseUrl + endpoint,
    ).replace(queryParameters: queryParams);
    final token = await AuthService.getToken() ?? "";
    if (kDebugMode) {
      AppLogger.log.i("========== HTTP REQUEST ==========");
      AppLogger.log.i("METHOD: GET");
      AppLogger.log.i("FULL URL: $uri");
      AppLogger.log.i("ENDPOINT: $endpoint");
      AppLogger.log.i("QUERY PARAMS: $queryParams");
      AppLogger.log.i("TOKEN: len=${token.length}");
      AppLogger.log.i("==================================");
    }
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception("HTTP ${response.statusCode}: ${response.body}");
    }
  }

  Future<Map<String, dynamic>> uploadImageMultipart({
    required String endpoint,
    required File imageFile,
    String fieldName = 'image',
    String? token,
    Map<String, String>? additionalFields,
  }) async {
    final uri = Uri.parse(baseUrl + endpoint);
    final request = http.MultipartRequest('POST', uri);

    request.headers.addAll({
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    });
    final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
    final extension = mimeType.split('/').last;
    final multipartFile = await http.MultipartFile.fromPath(
      fieldName,
      imageFile.path,

      filename: imageFile.path.split(Platform.pathSeparator).last,
      contentType: http_parser.MediaType('image', extension),
    );
    request.files.add(multipartFile);

    if (additionalFields != null && additionalFields.isNotEmpty) {
      request.fields.addAll(additionalFields);
    }

    // ✅ ONE PRINT: what you're sending (URL + body parts)
    _debugLog(
        'SENDING -> URL: ${request.url}\n'
            'FIELDS: ${request.fields}\n'
            'FILES: ${request.files.map((f) => {
          "field": f.field,
          "filename": f.filename,
          "length": f.length,
        }).toList()}\n'
    );

    try {
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      // ✅ ONE PRINT: response
      _debugLog(
          'RESPONSE <- ${response.statusCode}\n'
              'BODY: ${response.body}\n'
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception("Upload failed - HTTP ${response.statusCode}: ${response.body}");
      }
    } on SocketException {
      throw FetchDataException('No Internet Connection');
    }
  }
/*
  Future<Map<String, dynamic>> uploadImageMultipart({
    required String endpoint,
    required File imageFile,
    String fieldName = 'image',
    String? token,
    Map<String, String>? additionalFields,
  }) async {
    final uri = Uri.parse(baseUrl + endpoint);

    final request = http.MultipartRequest('POST', uri);

    request.headers.addAll({
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    });

    // ❌ TEMP DISABLE: file attach to multipart (HIDE form-data)
    final multipartFile = await http.MultipartFile.fromPath(
      fieldName,
      imageFile.path,
      filename: imageFile.path.split(Platform.pathSeparator).last,
    );
    request.files.add(multipartFile);

    // ❌ TEMP DISABLE: extra fields attach (HIDE form-data)
      if (additionalFields != null && additionalFields.isNotEmpty) {
        request.fields.addAll(additionalFields);
      }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      AppLogger.log.i(response);

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
          "Upload failed - HTTP ${response.statusCode}: ${response.body}",
        );
      }
    } on SocketException {
      throw FetchDataException('No Internet Connection');
    } catch (e) {
      AppLogger.log.e(e);
      rethrow;
    }
  }*/

  // Future<Map<String, dynamic>> uploadImageMultipart({
  //   required String endpoint,
  //   required File imageFile,
  //   String fieldName = 'image',
  //   String? token,
  //   Map<String, String>? additionalFields,
  // }) async {
  //   final uri = Uri.parse(baseUrl + endpoint);
  //
  //   final request = http.MultipartRequest('POST', uri);
  //
  //   // Headers (NEVER set 'Content-Type' manually for MultipartRequest — http does it)
  //   request.headers.addAll({
  //     'Accept': 'application/json',
  //     if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
  //   });
  //
  //   // Add the image file
  //   final multipartFile = await http.MultipartFile.fromPath(
  //     fieldName,
  //     imageFile.path,
  //     filename: imageFile.path.split(Platform.pathSeparator).last,
  //     // contentType: MediaType('image', 'jpeg'), // optional — backend usually detects
  //   );
  //   request.files.add(multipartFile);
  //
  //   // Add any extra text fields (if needed in future)
  //   if (additionalFields != null) {
  //     request.fields.addAll(additionalFields);
  //   }
  //
  //   // ─── Debug print request summary ───────────────────────────────
  //   _debugLog('\n' + '=' * 60);
  //   _debugLog('📤 MULTIPART UPLOAD REQUEST');
  //   _debugLog('📤 URL: $uri');
  //   _debugLog('📤 Headers: ${request.headers}');
  //   _debugLog('📤 Fields: ${request.fields}');
  //   _debugLog('📤 Files: ${request.files.map((f) => f.filename).toList()}');
  //   _debugLog('-' * 60);
  //
  //   try {
  //     final streamedResponse = await request.send();
  //     final response = await http.Response.fromStream(streamedResponse);
  //
  //     _debugLog('📥 Status Code: ${response.statusCode}');
  //     _debugLog('📥 Response Body:');
  //     _debugLog(response.body);
  //     _debugLog('=' * 60 + '\n');
  //
  //     if (response.statusCode == 200) {
  //       try {
  //         return json.decode(response.body) as Map<String, dynamic>;
  //       } catch (e) {
  //         throw Exception("Failed to parse JSON: $e\nBody: ${response.body}");
  //       }
  //     } else {
  //       throw Exception(
  //         "Upload failed - HTTP ${response.statusCode}: ${response.body}",
  //       );
  //     }
  //   } on SocketException {
  //     throw FetchDataException('No Internet Connection');
  //   } catch (e) {
  //     _debugLog('🔴 UPLOAD ERROR: $e');
  //     rethrow;
  //   }
  // }

  Future<Map<String, dynamic>> getResponseV4(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.parse(
      baseUrl + endpoint,
    ).replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer ',
      },
    );

    _debugLog("Status Code: ${response.statusCode}");
    _debugLog("Raw body: ${response.body}");

    if (response.statusCode == 200) {
      try {
        // First decode — might be a stringified JSON
        dynamic firstDecode = json.decode(response.body);

        // If it's a String, decode again
        if (firstDecode is String) {
          _debugLog("Double-encoded JSON detected, decoding again...");
          firstDecode = json.decode(firstDecode);
        }

        // Now it should be Map<String, dynamic>
        if (firstDecode is Map<String, dynamic>) {
          return firstDecode;
        } else {
          throw Exception("Unexpected response format");
        }
      } catch (e) {
        _debugLog("JSON decode error: $e");
        rethrow;
      }
    } else {
      throw Exception("HTTP ${response.statusCode}: ${response.body}");
    }
  }

  // In NetworkApiService.dart

  Future<String> rawGetResponse(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.parse(
      baseUrl + endpoint,
    ).replace(queryParameters: queryParams);

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer ', 'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception("HTTP ${response.statusCode}: ${response.body}");
    }
  }

  // Future getlaunchResponse(String url) async {
  //   dynamic responseJson;
  //   Map<String, String> headers = {"Authorization": "Bearer ${token.$}"};
  //   try {
  //     final response =
  //         await http.get(Uri.parse(lanchpad + url), headers: headers);
  //     responseJson = returnResponse(response);
  //   } on SocketException {
  //     throw FetchDataException('No Internet Connection');
  //   }
  //   return responseJson;
  // }
  //
  // Future getEarnResponse(String url) async {
  //   dynamic responseJson;
  //   Map<String, String> headers = {"Authorization": "Bearer ${token.$}"};
  //   try {
  //     final response =
  //         await http.get(Uri.parse(simpleEarn + url), headers: headers);
  //     responseJson = returnResponse(response);
  //   } on SocketException {
  //     throw FetchDataException('No Internet Connection');
  //   }
  //   return responseJson;
  // }
  //
  // Future getResponseV2(String url) async {
  //   dynamic responseJson;
  //   Map<String, String> headers = {"Authorization": "Bearer ${token.$}"};
  //   try {
  //     final response =
  //         await http.get(Uri.parse(baseUrlV2 + url), headers: headers);
  //     responseJson = returnResponse(response);
  //   } on SocketException {
  //     throw FetchDataException('No Internet Connection');
  //   }
  //   return responseJson;
  // }
  //
  // Future getResponsePerpetual(String url) async {
  //   dynamic responseJson;
  //   Map<String, String> headers = {"Authorization": "Bearer ${token.$}"};
  //   try {
  //     final response =
  //         await http.get(Uri.parse(perpetualURL + url), headers: headers);
  //     responseJson = returnResponse(response);
  //   } on SocketException {
  //     throw FetchDataException('No Internet Connection');
  //   }
  //   return responseJson;
  // }

  Future getResponseFirebase(String url) async {
    dynamic responseJson;
    // Map<String, String> headers = {"Authorization": "Bearer ${token.$}"};
    try {
      final response = await http.get(
        Uri.parse("https://fibitpro-2bcc3-default-rtdb.firebaseio.com/"),
      );
      responseJson = returnResponse(response);
    } on SocketException {
      throw FetchDataException('No Internet Connection');
    }
    return responseJson;
  }

  @override
  Future postResponse(String url, {Map<String, dynamic>? body}) async {
    _debugLog("$url");
    dynamic responseJson;
    var data = json.encode(body);
    var headers = {
      "content-type": "application/json",
      "Accept": "application/json",
    };
    _debugLog(data);
    try {
      await http
          .post(Uri.parse(baseUrl + url), headers: headers, body: data)
          .then((value) {
            responseJson = jsonDecode(value.body);
            _debugLog("${baseUrl + url}");
            _debugLog("///attend$responseJson");
          });
    } on SocketException {
      throw FetchDataException('No Internet Connection');
    }
    return responseJson;
  }

  Future<dynamic> postResponseV2(
    String url, {
    Map<String, dynamic>? body,
  }) async {
    // final token = await UserPreferences().getToken()??"";
    // final String? token = await AuthService.getToken();

    // _debugLog("$token");
    final token = await AuthService.getToken() ?? "";
    dynamic responseJson;
    var data = json.encode(body);
    var headers = {
      "Authorization": "Bearer $token", // add token
      "content-type": "application/json",
      "Accept": "application/json",
    };

    // PRINT REQUEST DETAILS
    _debugLog('\n' + '=' * 60);
    _debugLog('📤 POST REQUEST V2');
    _debugLog('📤 URL: ${baseUrl + url}');
    _debugLog('📤 Headers: ${jsonEncode(headers)}');
    _debugLog('📤 Body:');
    if (body != null) {
      try {
        final encoder = JsonEncoder.withIndent('  ');
        _debugLog(encoder.convert(body));
      } catch (e) {
        _debugLog(body.toString());
      }
    } else {
      _debugLog('No body');
    }
    _debugLog('-' * 40);

    try {
      final startTime = DateTime.now();

      await http
          .post(Uri.parse(baseUrl + url), headers: headers, body: data)
          .then((response) {
            final endTime = DateTime.now();
            final duration = endTime.difference(startTime);

            // PRINT RESPONSE DETAILS
            _debugLog('📥 RESPONSE V2');
            _debugLog('📥 Status Code: ${response.statusCode}');
            _debugLog('📥 Response Time: ${duration.inMilliseconds}ms');
            _debugLog('📥 Response Headers: ${response.headers}');
            _debugLog('📥 Response Body:');

            try {
              responseJson = jsonDecode(response.body);

              // Pretty print JSON response
              final encoder = JsonEncoder.withIndent('  ');
              _debugLog(encoder.convert(responseJson));

              // Print success/failure summary
              _debugLog('\n📊 RESPONSE SUMMARY:');
              if (responseJson is Map) {
                if (responseJson.containsKey('success')) {
                  _debugLog('   Success: ${responseJson['success']}');
                }
                if (responseJson.containsKey('message')) {
                  _debugLog('   Message: ${responseJson['message']}');
                }
                if (responseJson.containsKey('error')) {
                  _debugLog('   Error: ${responseJson['error']}');
                }

                // For trade orders, print specific details
                if (url.contains('orders/buy') || url.contains('orders/sell')) {
                  _debugLog('\n💱 ORDER DETAILS:');
                  if (responseJson.containsKey('newOrders') &&
                      responseJson['newOrders'] is List) {
                    final orders = responseJson['newOrders'];
                    _debugLog('   Number of Orders Created: ${orders.length}');
                    for (var i = 0; i < orders.length; i++) {
                      final order = orders[i];
                      _debugLog('   Order ${i + 1}:');
                      _debugLog('     - ID: ${order['_id'] ?? 'N/A'}');
                      _debugLog('     - Side: ${order['side'] ?? 'N/A'}');
                      _debugLog('     - Action: ${order['action'] ?? 'N/A'}');
                      _debugLog('     - Shares: ${order['shares'] ?? 'N/A'}');
                      _debugLog(
                        '     - Price: \$${order['price_per_share'] ?? 'N/A'}',
                      );
                      _debugLog('     - Created: ${order['createdAt'] ?? 'N/A'}');
                    }
                  }
                  if (responseJson.containsKey('totalSpent')) {
                    _debugLog('   Total Spent: \$${responseJson['totalSpent']}');
                  }
                }
              }
            } catch (e) {
              // If not JSON, print as text
              responseJson = response.body;
              _debugLog(response.body);
            }

            _debugLog('=' * 60 + '\n');
          })
          .catchError((error) {
            _debugLog('🔴 POST REQUEST ERROR:');
            _debugLog('🔴 Error: $error');
            _debugLog('🔴 URL: ${baseUrl + url}');
            _debugLog('=' * 60 + '\n');
            throw error;
          });
    } on SocketException {
      _debugLog('🔴 NETWORK ERROR: No Internet Connection');
      _debugLog('🔴 URL: ${baseUrl + url}');
      _debugLog('=' * 60 + '\n');
      throw FetchDataException('No Internet Connection');
    } catch (e) {
      _debugLog('🔴 UNEXPECTED ERROR:');
      _debugLog('🔴 Error: $e');
      _debugLog('🔴 URL: ${baseUrl + url}');
      _debugLog('=' * 60 + '\n');
      rethrow;
    }

    return responseJson;
  }

  Future<dynamic> postResponseV3(
    String url, {
    Map<String, dynamic>? body,
  }) async {
    final token = await AuthService.getToken() ?? "";
    // final String? token = await AuthService.getToken();

    // _debugLog("$token");
    dynamic responseJson;
    var data = json.encode(body);
    var headers = {
      "Authorization": "Bearer $token", // add token
      "content-type": "application/json",
      "Accept": "application/json",
    };

    // PRINT REQUEST DETAILS
    _debugLog('\n' + '=' * 60);
    _debugLog('📤 POST REQUEST V2');
    _debugLog('📤 URL: ${baseUrl + url}');
    _debugLog('📤 Headers: ${jsonEncode(headers)}');
    _debugLog('📤 Body:');
    if (body != null) {
      try {
        final encoder = JsonEncoder.withIndent('  ');
        _debugLog(encoder.convert(body));
      } catch (e) {
        _debugLog(body.toString());
      }
    } else {
      _debugLog('No body');
    }
    _debugLog('-' * 40);

    try {
      final startTime = DateTime.now();

      await http
          .post(Uri.parse(baseUrl + url), headers: headers, body: data)
          .then((response) {
            final endTime = DateTime.now();
            final duration = endTime.difference(startTime);

            // PRINT RESPONSE DETAILS
            _debugLog('📥 RESPONSE V2');
            _debugLog('📥 Status Code: ${response.statusCode}');
            _debugLog('📥 Response Time: ${duration.inMilliseconds}ms');
            _debugLog('📥 Response Headers: ${response.headers}');
            _debugLog('📥 Response Body:');

            try {
              responseJson = jsonDecode(response.body);

              // Pretty print JSON response
              final encoder = JsonEncoder.withIndent('  ');
              _debugLog(encoder.convert(responseJson));

              // Print success/failure summary
              _debugLog('\n📊 RESPONSE SUMMARY:');
              if (responseJson is Map) {
                if (responseJson.containsKey('success')) {
                  _debugLog('   Success: ${responseJson['success']}');
                }
                if (responseJson.containsKey('message')) {
                  _debugLog('   Message: ${responseJson['message']}');
                }
                if (responseJson.containsKey('error')) {
                  _debugLog('   Error: ${responseJson['error']}');
                }

                // For trade orders, print specific details
                if (url.contains('orders/buy') || url.contains('orders/sell')) {
                  _debugLog('\n💱 ORDER DETAILS:');
                  if (responseJson.containsKey('newOrders') &&
                      responseJson['newOrders'] is List) {
                    final orders = responseJson['newOrders'];
                    _debugLog('   Number of Orders Created: ${orders.length}');
                    for (var i = 0; i < orders.length; i++) {
                      final order = orders[i];
                      _debugLog('   Order ${i + 1}:');
                      _debugLog('     - ID: ${order['_id'] ?? 'N/A'}');
                      _debugLog('     - Side: ${order['side'] ?? 'N/A'}');
                      _debugLog('     - Action: ${order['action'] ?? 'N/A'}');
                      _debugLog('     - Shares: ${order['shares'] ?? 'N/A'}');
                      _debugLog(
                        '     - Price: \$${order['price_per_share'] ?? 'N/A'}',
                      );
                      _debugLog('     - Created: ${order['createdAt'] ?? 'N/A'}');
                    }
                  }
                  if (responseJson.containsKey('totalSpent')) {
                    _debugLog('   Total Spent: \$${responseJson['totalSpent']}');
                  }
                }
              }
            } catch (e) {
              // If not JSON, print as text
              responseJson = response.body;
              _debugLog(response.body);
            }

            _debugLog('=' * 60 + '\n');
          })
          .catchError((error) {
            _debugLog('🔴 POST REQUEST ERROR:');
            _debugLog('🔴 Error: $error');
            _debugLog('🔴 URL: ${baseUrl + url}');
            _debugLog('=' * 60 + '\n');
            throw error;
          });
    } on SocketException {
      _debugLog('🔴 NETWORK ERROR: No Internet Connection');
      _debugLog('🔴 URL: ${baseUrl + url}');
      _debugLog('=' * 60 + '\n');
      throw FetchDataException('No Internet Connection');
    } catch (e) {
      _debugLog('🔴 UNEXPECTED ERROR:');
      _debugLog('🔴 Error: $e');
      _debugLog('🔴 URL: ${baseUrl + url}');
      _debugLog('=' * 60 + '\n');
      rethrow;
    }

    return responseJson;
  }

  Future<Map<String, dynamic>> putResponse(
    String url, {
    required Map<String, dynamic> body,
  }) async {
    // final token = await AuthService.getToken();
    final response = await http.put(
      Uri.parse(baseUrl + url),
      headers: {"Content-Type": "application/json", "Authorization": "Bearer "},
      body: json.encode(body),
    );
    _debugLog("${response.body}");
    return json.decode(response.body);
  }

  // Future postResponseTempBearPull(String url,
  //     {Map<String, dynamic>? body}) async {
  //   dynamic responseJson;
  //   var data = json.encode(body);
  //   var headers = {
  //     "Authorization": "Bearer ${token.$}",
  //     "content-type": "application/json",
  //     "Accept": "application/json"
  //   };
  //   _debugLog(data);
  //   try {
  //     await http
  //         .post(Uri.parse(bearPull + url), headers: headers, body: data)
  //         .then((value) {
  //       responseJson = jsonDecode(value.body);
  //     });
  //   } on SocketException {
  //     throw FetchDataException('No Internet Connection');
  //   }
  //   return responseJson;
  // }
  //
  // Future postResponsePerpetual(String url, {Map<String, dynamic>? body}) async {
  //   dynamic responseJson;
  //   var data = json.encode(body);
  //   var headers = {
  //     "Authorization": "Bearer ${token.$}",
  //     "content-type": "application/json",
  //     "Accept": "application/json"
  //   };
  //   _debugLog(data);
  //   try {
  //     await http
  //         .post(Uri.parse(perpetualURL + url), headers: headers, body: data)
  //         .then((value) {
  //       responseJson = jsonDecode(value.body);
  //     });
  //   } on SocketException {
  //     throw FetchDataException('No Internet Connection');
  //   }
  //   return responseJson;
  // }
  //
  // Future postResponseLaunch(String url, {Map<String, dynamic>? body}) async {
  //   dynamic responseJson;
  //   var data = json.encode(body);
  //   var headers = {
  //     "Authorization": "Bearer ${token.$}",
  //     "content-type": "application/json",
  //     "Accept": "application/json"
  //   };
  //   _debugLog(data);
  //   try {
  //     await http
  //         .post(Uri.parse(lanchpad + url), headers: headers, body: data)
  //         .then((value) {
  //       responseJson = jsonDecode(value.body);
  //     });
  //   } on SocketException {
  //     throw FetchDataException('No Internet Connection');
  //   }
  //   return responseJson;
  // }
  //
  // Future postResponseEarn(String url, {Map<String, dynamic>? body}) async {
  //   dynamic responseJson;
  //   var data = json.encode(body);
  //   var headers = {
  //     "Authorization": "Bearer ${token.$}",
  //     "content-type": "application/json",
  //     "Accept": "application/json"
  //   };
  //   _debugLog(data);
  //   try {
  //     await http
  //         .post(Uri.parse(simpleEarn + url), headers: headers, body: data)
  //         .then((value) {
  //       responseJson = jsonDecode(value.body);
  //     });
  //   } on SocketException {
  //     throw FetchDataException('No Internet Connection');
  //   }
  //   return responseJson;
  // }
  //
  // Future postResponseLaunchv2(String url, {Map<String, dynamic>? body}) async {
  //   dynamic responseJson;
  //   var data = json.encode(body);
  //   var headers = {
  //     "Authorization": "Bearer ${token.$}",
  //     "content-type": "application/json",
  //     "Accept": "application/json"
  //   };
  //   _debugLog(data);
  //   try {
  //     await http
  //         .post(Uri.parse(launchpadV2 + url), headers: headers, body: data)
  //         .then((value) {
  //       responseJson = jsonDecode(value.body);
  //     });
  //   } on SocketException {
  //     throw FetchDataException('No Internet Connection');
  //   }
  //   return responseJson;
  // }
  //
  // Future postResponseV2(String url, {Map<String, dynamic>? body}) async {
  //   dynamic responseJson;
  //   var data = json.encode(body);
  //   var headers = {
  //     "Authorization": "Bearer ${token.$}",
  //     "content-type": "application/json",
  //     "Accept": "application/json"
  //   };
  //   _debugLog(data);
  //   try {
  //     await http
  //         .post(Uri.parse(baseUrlV2 + url), headers: headers, body: data)
  //         .then((value) {
  //       responseJson = jsonDecode(value.body);
  //     });
  //   } on SocketException {
  //     throw FetchDataException('No Internet Connection');
  //   }
  //   return responseJson;
  // }
  //
  // In NetworkApiService.dart

  Future<Map<String, dynamic>> multipartProcedure(
    String url,
    List<http.MultipartFile> files, {
    Map<String, String>? fields,
    String? token,
  }) async {
    final uri = Uri.parse(baseUrl + url);
    _debugLog("$uri");
    final request = http.MultipartRequest('POST', uri);

    // ONLY these headers — DO NOT set content-type!
    request.headers.addAll({
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    });

    // Add files
    request.files.addAll(files);

    // Add fields
    if (fields != null) {
      request.fields.addAll(fields);
    }

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      _debugLog("Upload Status: ${streamedResponse.statusCode}");
      _debugLog("Upload Response: ${response.body}");

      if (streamedResponse.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
          "Server error: ${streamedResponse.statusCode} - ${response.body}",
        );
      }
    } catch (e) {
      throw Exception("Upload failed: $e");
    }
  }

  //
  // multipartProcedureV1(String url, List<http.MultipartFile> files,
  //     {Map<String, dynamic>? body}) async {
  //   dynamic responseJson;
  //   var request = http.MultipartRequest('POST', Uri.parse(baseUrl + url));
  //   Map<String, String> data = body!.cast();
  //   //for token
  //   _debugLog(data);
  //   request.headers.addAll({
  //     "Authorization": "Bearer ${token.$}",
  //     "content-type": "multipart/form-data",
  //     "Accept": "multipart/form-data"
  //   });
  //
  //   try {
  //     //for image and videos and files
  //     // http.MultipartFile f = await http.MultipartFile.fromPath("images[]", file!.path);
  //     for (var i = 0; i < files.length; i++) {
  //       request.files.add(files[i]);
  //     }
  //     // request.files.addAll(files);
  //     request.fields.addAll(data);
  //     var response = await request.send();
  //
  //     //for getting and decoding the response into json format
  //     var responsed = await http.Response.fromStream(response);
  //     responseJson = json.decode(responsed.body);
  //   } on SocketException {
  //     throw FetchDataException('No Internet Connection');
  //   }
  //   return responseJson;
  // }

  // Future fcmPostResponse({Map<String, dynamic>? body}) async {
  //   dynamic responseJson;
  //   var data = json.encode(body);
  //   var headers = {
  //     "Authorization": "Bearer ${FCMConfiguration.serverToken}",
  //     "content-type": "application/json",
  //     "Accept": "application/json"
  //   };
  //   _debugLog(data);
  //   try {
  //     await http
  //         .post(Uri.parse("https://fcm.googleapis.com/fcm/send"),
  //             headers: headers, body: data)
  //         .then((value) {
  //       responseJson = jsonDecode(value.body);
  //     });
  //   } on SocketException {
  //     throw FetchDataException('No Internet Connection');
  //   }
  //   _debugLog(responseJson);
  //   return responseJson;
  // }

  dynamic returnResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
        dynamic responseJson = jsonDecode(response.body);
        return responseJson;
      case 400:
        throw BadRequestException(response.toString());
      case 401:
      case 403:
        throw UnauthorisedException(response.body.toString());
      case 404:
        throw UnauthorisedException(response.body.toString());
      case 500:
      default:
        throw FetchDataException(
          'Error occured while communication with server'
          ' with status code : ${response.statusCode}',
        );
    }
  }
}
