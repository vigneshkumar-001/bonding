import 'dart:convert';
import 'dart:io';
import 'package:bonding_app/APIService/Remote/AppException.dart';
import 'package:bonding_app/APIService/Remote/network/BaseApiService.dart'
    show BaseApiService;
import 'package:bonding_app/BondingScreens/AuthService.dart';
import 'package:bonding_app/Bonding_Utils/AppLogger/app_logger.dart';
import 'package:bonding_app/Services/Session/session_guard.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart' as http_parser;
import 'package:mime/mime.dart';
// import 'package:prod/APIService/Remote/AppException.dart';

class NetworkApiService extends BaseApiService {
  @override
  Future getResponse(String url) async {
    print("efcdececdecc");
    // final String? token = await AuthService.getToken();
    dynamic responseJson;
    Map<String, String> headers = {"Authorization": "Bearer "}; // add token
    try {
      print("evceadcc");
      final response = await http.get(
        Uri.parse(baseUrl + url),
        headers: headers,
      );
      print("??>>?>?>?>$response");
      responseJson = returnResponse(response);
      print("????????$responseJson");
      print("////////////${baseUrl + url}");
    } on SocketException {
      throw FetchDataException('No Internet Connection');
    }
    return responseJson;
  }

  Future getResponseV3(String url) async {
    print("efcdececdecc");

    dynamic responseJson;
    // add token
    try {
      print("evceadcc");
      final response = await http.get(Uri.parse(url));
      print("??>>?>?>?>$response");
      responseJson = returnResponse(response);
      print("????????$responseJson");
      print("////////////${url}");
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
    AppLogger.log.i("========== HTTP REQUEST ==========");
    AppLogger.log.i("METHOD: GET");
    AppLogger.log.i("FULL URL: $uri");
    AppLogger.log.i("ENDPOINT: $endpoint");
    AppLogger.log.i("QUERY PARAMS: $queryParams");
    AppLogger.log.i("TOKEN: $token");
    AppLogger.log.i(
      "HEADERS: {Authorization: Bearer $token, Accept: application/json}",
    );
 
    AppLogger.log.i("==================================");
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );

    SessionGuard().inspect(response.statusCode, response.body);

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
    print(
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
      print(
          'RESPONSE <- ${response.statusCode}\n'
              'BODY: ${response.body}\n'
      );

      SessionGuard().inspect(response.statusCode, response.body);

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
  //   print('\n' + '=' * 60);
  //   print('📤 MULTIPART UPLOAD REQUEST');
  //   print('📤 URL: $uri');
  //   print('📤 Headers: ${request.headers}');
  //   print('📤 Fields: ${request.fields}');
  //   print('📤 Files: ${request.files.map((f) => f.filename).toList()}');
  //   print('-' * 60);
  //
  //   try {
  //     final streamedResponse = await request.send();
  //     final response = await http.Response.fromStream(streamedResponse);
  //
  //     print('📥 Status Code: ${response.statusCode}');
  //     print('📥 Response Body:');
  //     print(response.body);
  //     print('=' * 60 + '\n');
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
  //     print('🔴 UPLOAD ERROR: $e');
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

    print("Status Code: ${response.statusCode}");
    print("Raw body: ${response.body}");

    SessionGuard().inspect(response.statusCode, response.body);

    if (response.statusCode == 200) {
      try {
        // First decode — might be a stringified JSON
        dynamic firstDecode = json.decode(response.body);

        // If it's a String, decode again
        if (firstDecode is String) {
          print("Double-encoded JSON detected, decoding again...");
          firstDecode = json.decode(firstDecode);
        }

        // Now it should be Map<String, dynamic>
        if (firstDecode is Map<String, dynamic>) {
          return firstDecode;
        } else {
          throw Exception("Unexpected response format");
        }
      } catch (e) {
        print("JSON decode error: $e");
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

    SessionGuard().inspect(response.statusCode, response.body);

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
    print("$url");
    dynamic responseJson;
    var data = json.encode(body);
    var headers = {
      "content-type": "application/json",
      "Accept": "application/json",
    };
    print(data);
    try {
      await http
          .post(Uri.parse(baseUrl + url), headers: headers, body: data)
          .then((value) {
            SessionGuard().inspect(value.statusCode, value.body);
            responseJson = jsonDecode(value.body);
            print("${baseUrl + url}");
            print("///attend$responseJson");
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

    // print("$token");
    final token = await AuthService.getToken() ?? "";
    dynamic responseJson;
    var data = json.encode(body);
    var headers = {
      "Authorization": "Bearer $token", // add token
      "content-type": "application/json",
      "Accept": "application/json",
    };

    // PRINT REQUEST DETAILS
    print('\n' + '=' * 60);
    print('📤 POST REQUEST V2');
    print('📤 URL: ${baseUrl + url}');
    print('📤 Headers: ${jsonEncode(headers)}');
    print('📤 Body:');
    if (body != null) {
      try {
        final encoder = JsonEncoder.withIndent('  ');
        print(encoder.convert(body));
      } catch (e) {
        print(body.toString());
      }
    } else {
      print('No body');
    }
    print('-' * 40);

    try {
      final startTime = DateTime.now();

      await http
          .post(Uri.parse(baseUrl + url), headers: headers, body: data)
          .then((response) {
            final endTime = DateTime.now();
            final duration = endTime.difference(startTime);

            // PRINT RESPONSE DETAILS
            print('📥 RESPONSE V2');
            print('📥 Status Code: ${response.statusCode}');
            print('📥 Response Time: ${duration.inMilliseconds}ms');
            print('📥 Response Headers: ${response.headers}');
            print('📥 Response Body:');

            SessionGuard().inspect(response.statusCode, response.body);

            try {
              responseJson = jsonDecode(response.body);

              // Pretty print JSON response
              final encoder = JsonEncoder.withIndent('  ');
              print(encoder.convert(responseJson));

              // Print success/failure summary
              print('\n📊 RESPONSE SUMMARY:');
              if (responseJson is Map) {
                if (responseJson.containsKey('success')) {
                  print('   Success: ${responseJson['success']}');
                }
                if (responseJson.containsKey('message')) {
                  print('   Message: ${responseJson['message']}');
                }
                if (responseJson.containsKey('error')) {
                  print('   Error: ${responseJson['error']}');
                }

                // For trade orders, print specific details
                if (url.contains('orders/buy') || url.contains('orders/sell')) {
                  print('\n💱 ORDER DETAILS:');
                  if (responseJson.containsKey('newOrders') &&
                      responseJson['newOrders'] is List) {
                    final orders = responseJson['newOrders'];
                    print('   Number of Orders Created: ${orders.length}');
                    for (var i = 0; i < orders.length; i++) {
                      final order = orders[i];
                      print('   Order ${i + 1}:');
                      print('     - ID: ${order['_id'] ?? 'N/A'}');
                      print('     - Side: ${order['side'] ?? 'N/A'}');
                      print('     - Action: ${order['action'] ?? 'N/A'}');
                      print('     - Shares: ${order['shares'] ?? 'N/A'}');
                      print(
                        '     - Price: \$${order['price_per_share'] ?? 'N/A'}',
                      );
                      print('     - Created: ${order['createdAt'] ?? 'N/A'}');
                    }
                  }
                  if (responseJson.containsKey('totalSpent')) {
                    print('   Total Spent: \$${responseJson['totalSpent']}');
                  }
                }
              }
            } catch (e) {
              // If not JSON, print as text
              responseJson = response.body;
              print(response.body);
            }

            print('=' * 60 + '\n');
          })
          .catchError((error) {
            print('🔴 POST REQUEST ERROR:');
            print('🔴 Error: $error');
            print('🔴 URL: ${baseUrl + url}');
            print('=' * 60 + '\n');
            throw error;
          });
    } on SocketException {
      print('🔴 NETWORK ERROR: No Internet Connection');
      print('🔴 URL: ${baseUrl + url}');
      print('=' * 60 + '\n');
      throw FetchDataException('No Internet Connection');
    } catch (e) {
      print('🔴 UNEXPECTED ERROR:');
      print('🔴 Error: $e');
      print('🔴 URL: ${baseUrl + url}');
      print('=' * 60 + '\n');
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

    // print("$token");
    dynamic responseJson;
    var data = json.encode(body);
    var headers = {
      "Authorization": "Bearer $token", // add token
      "content-type": "application/json",
      "Accept": "application/json",
    };

    // PRINT REQUEST DETAILS
    print('\n' + '=' * 60);
    print('📤 POST REQUEST V2');
    print('📤 URL: ${baseUrl + url}');
    print('📤 Headers: ${jsonEncode(headers)}');
    print('📤 Body:');
    if (body != null) {
      try {
        final encoder = JsonEncoder.withIndent('  ');
        print(encoder.convert(body));
      } catch (e) {
        print(body.toString());
      }
    } else {
      print('No body');
    }
    print('-' * 40);

    try {
      final startTime = DateTime.now();

      await http
          .post(Uri.parse(baseUrl + url), headers: headers, body: data)
          .then((response) {
            final endTime = DateTime.now();
            final duration = endTime.difference(startTime);

            // PRINT RESPONSE DETAILS
            print('📥 RESPONSE V2');
            print('📥 Status Code: ${response.statusCode}');
            print('📥 Response Time: ${duration.inMilliseconds}ms');
            print('📥 Response Headers: ${response.headers}');
            print('📥 Response Body:');

            SessionGuard().inspect(response.statusCode, response.body);

            try {
              responseJson = jsonDecode(response.body);

              // Pretty print JSON response
              final encoder = JsonEncoder.withIndent('  ');
              print(encoder.convert(responseJson));

              // Print success/failure summary
              print('\n📊 RESPONSE SUMMARY:');
              if (responseJson is Map) {
                if (responseJson.containsKey('success')) {
                  print('   Success: ${responseJson['success']}');
                }
                if (responseJson.containsKey('message')) {
                  print('   Message: ${responseJson['message']}');
                }
                if (responseJson.containsKey('error')) {
                  print('   Error: ${responseJson['error']}');
                }

                // For trade orders, print specific details
                if (url.contains('orders/buy') || url.contains('orders/sell')) {
                  print('\n💱 ORDER DETAILS:');
                  if (responseJson.containsKey('newOrders') &&
                      responseJson['newOrders'] is List) {
                    final orders = responseJson['newOrders'];
                    print('   Number of Orders Created: ${orders.length}');
                    for (var i = 0; i < orders.length; i++) {
                      final order = orders[i];
                      print('   Order ${i + 1}:');
                      print('     - ID: ${order['_id'] ?? 'N/A'}');
                      print('     - Side: ${order['side'] ?? 'N/A'}');
                      print('     - Action: ${order['action'] ?? 'N/A'}');
                      print('     - Shares: ${order['shares'] ?? 'N/A'}');
                      print(
                        '     - Price: \$${order['price_per_share'] ?? 'N/A'}',
                      );
                      print('     - Created: ${order['createdAt'] ?? 'N/A'}');
                    }
                  }
                  if (responseJson.containsKey('totalSpent')) {
                    print('   Total Spent: \$${responseJson['totalSpent']}');
                  }
                }
              }
            } catch (e) {
              // If not JSON, print as text
              responseJson = response.body;
              print(response.body);
            }

            print('=' * 60 + '\n');
          })
          .catchError((error) {
            print('🔴 POST REQUEST ERROR:');
            print('🔴 Error: $error');
            print('🔴 URL: ${baseUrl + url}');
            print('=' * 60 + '\n');
            throw error;
          });
    } on SocketException {
      print('🔴 NETWORK ERROR: No Internet Connection');
      print('🔴 URL: ${baseUrl + url}');
      print('=' * 60 + '\n');
      throw FetchDataException('No Internet Connection');
    } catch (e) {
      print('🔴 UNEXPECTED ERROR:');
      print('🔴 Error: $e');
      print('🔴 URL: ${baseUrl + url}');
      print('=' * 60 + '\n');
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
    print("${response.body}");
    SessionGuard().inspect(response.statusCode, response.body);
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
  //   print(data);
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
  //   print(data);
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
  //   print(data);
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
  //   print(data);
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
  //   print(data);
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
  //   print(data);
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
    print("$uri");
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

      print("Upload Status: ${streamedResponse.statusCode}");
      print("Upload Response: ${response.body}");

      SessionGuard().inspect(streamedResponse.statusCode, response.body);

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
  //   print(data);
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
  //   print(data);
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
  //   print(responseJson);
  //   return responseJson;
  // }

  dynamic returnResponse(http.Response response) {
    SessionGuard().inspect(response.statusCode, response.body);
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
