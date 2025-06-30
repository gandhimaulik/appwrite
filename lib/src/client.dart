import 'enums.dart';
import 'package:http/http.dart' as http;
import 'client_stub.dart'
    if (dart.library.html) 'client_browser.dart'
    if (dart.library.io) 'client_io.dart';
import 'response.dart';
import 'upload_progress.dart';

/// [Client] that handles requests to Appwrite.
///
/// The [Client] is also responsible for managing user's sessions.
abstract class Client {
  /// The size for cunked uploads in bytes.
  static const int CHUNK_SIZE = 5*1024*1024;
  /// Holds configuration such as project.
  late Map<String, String> config;
  late String _endPoint;
  late String? _endPointRealtime;

  /// Appwrite endpoint.
  String get endPoint => _endPoint;
  /// Appwrite realtime endpoint.
  String? get endPointRealtime => _endPointRealtime;

  /// Initializes a [Client].
  ///
  /// [endPoint] (required) is the Appwrite server endpoint.
  /// [selfSigned] (optional, defaults to `false`) is whether to allow self-signed
  /// certificates. This is only applicable when using the default internal HTTP client on IO platforms.
  /// It is ignored if a custom [httpClient] is provided or on web platforms.
  /// [httpClient] (optional) is a custom `http.Client` instance to be used for making
  /// network requests. If not provided, a default platform-specific client will be used.
  /// When providing a custom client, you are responsible for its configuration (e.g., SSL verification, proxy settings).
  factory Client({
    String endPoint = 'https://HOSTNAME/v1',
    bool selfSigned = false,
    http.Client? httpClient,
  }) =>
      createClient(
          endPoint: endPoint,
          selfSigned: selfSigned,
          httpClient: httpClient);

  /// Handle OAuth2 session creation.
  Future webAuth(Uri url, {String? callbackUrlScheme});

  /// Upload a file in chunks.
  Future<Response> chunkedUpload({
    required String path,
    required Map<String, dynamic> params,
    required String paramName,
    required String idParamName,
    required Map<String, String> headers,
    Function(UploadProgress)? onProgress,
  });

  /// Set self signed to [status].
  /// 
  /// If self signed is true, [Client] will ignore invalid certificates.
  /// This is helpful in environments where your Appwrite
  /// instance does not have a valid SSL certificate.
  Client setSelfSigned({bool status = true});

  /// Set the Appwrite endpoint.
  Client setEndpoint(String endPoint);

  /// Set the Appwrite realtime endpoint.
  Client setEndPointRealtime(String endPoint);

  /// Set Project.
  ///
  /// Your project ID.
  Client setProject(value);

  /// Set JWT.
  ///
  /// Your secret JSON Web Token.
  Client setJWT(value);

  /// Set Locale.
  Client setLocale(value);

  /// Add headers that should be sent with all API calls.
  Client addHeader(String key, String value);

  /// Send the API request.
  Future<Response> call(HttpMethod method, {
    String path = '',
    Map<String, String> headers = const {},
    Map<String, dynamic> params = const {},
    ResponseType? responseType,
  });
}
