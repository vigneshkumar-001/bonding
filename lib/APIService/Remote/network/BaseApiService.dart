abstract class BaseApiService {
  // bitbab
   
  final String baseUrl = "https://bnd.twoofus.tech/api/v1/";
  //  final String baseUrl = "https://qbkqz1b4-3005.inc1.devtunnels.ms/api/v1/";
   
  final String baseUrlV2 = "";

  Future<dynamic> getResponse(String url);

  Future<dynamic> postResponse(String url, {Map<String, dynamic>? body});

  Future<dynamic> postResponseV2(String url, {Map<String, dynamic>? body});
}
