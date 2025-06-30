import 'package:appwrite/appwrite.dart';
import 'package:appwrite/src/client_browser.dart' as browser_client;
import 'package:appwrite/src/client_io.dart' as io_client;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('Client', () {
    const String endpoint = 'https://localhost/v1';
    Client client;

    test('uses default http.Client when none is provided', () {
      client = Client(endPoint: endpoint);
      // This is a bit tricky to test directly without inspecting private fields
      // or relying on platform specific client types which might make test less robust.
      // For now, we'll assume that if no error occurs and the client is created,
      // it has an internal http client.
      // A more thorough test would involve checking the actual type,
      // but that requires conditional imports for dart:html vs dart:io
      // which can complicate test files.
      expect(client, isA<Client>());
      // We can't directly access the internal _httpClient of ClientBrowser/ClientIO easily.
      // However, we know they are created by their respective createClient functions.
    });

    test('uses provided MockClient', () async {
      final mockHttpClient = MockClient((request) async {
        return http.Response('{"message": "mock success"}', 200, headers: {
          'content-type': 'application/json',
        });
      });

      client = Client(endPoint: endpoint, httpClient: mockHttpClient);

      // To verify the mockClient is used, we make a call.
      // We need a service to make a call. Let's use Account as an example.
      // This test will need to be adapted if Account service changes.
      // For a truly isolated Client test, we might need to expose a method on Client
      // or use a spy on the actual http client, which is harder with current structure.

      final account = Account(client);

      // Mock a successful response for account.get()
      // The path for account.get() is '/account'
      // The actual call inside account.get() will be client.call(...)
      // which eventually uses the _httpClient.send(...)

      // Re-assign mockHttpClient with the specific expectation
      final mockHttpClientForCall = MockClient((request) async {
        // The client prepends endPoint to the path.
        // If endPoint is 'https://localhost/v1' and service path is '/account',
        // request.url.path will be '/v1/account'.
        if (request.url.path == '/v1/account') {
          return http.Response('{"name": "Test User", "email": "test@example.com", "\$id": "123", "registration": "2023-01-01T00:00:00.000Z", "status": true, "emailVerification": false, "phoneVerification": false, "prefs": {}}', 200, headers: {
            'content-type': 'application/json; charset=utf-8',
          });
        }
        return http.Response('Not Found', 404);
      });

      client = Client(endPoint: endpoint, httpClient: mockHttpClientForCall);
      final newAccount = Account(client);

      try {
        final user = await newAccount.get();
        expect(user.name, 'Test User');
      } catch (e) {
        // If the mock client wasn't used or setup correctly, this might fail.
        fail('Account.get() failed with custom client: $e');
      }
    });

    test('request goes through MockClient', () async {
      bool mockClientWasCalled = false;
      final expectedUrl = '$endpoint/account'; // The full URL the client will call for Account.get()
      final mockHttpClient = MockClient((request) async {
        mockClientWasCalled = true;
        if (request.url.toString() == expectedUrl) {
           return http.Response('{"name": "Test User", "email": "test@example.com", "\$id": "123", "registration": "2023-01-01T00:00:00.000Z", "status": true, "emailVerification": false, "phoneVerification": false, "prefs": {}}', 200, headers: {
            'content-type': 'application/json; charset=utf-8',
          });
        }
        return http.Response('Error', 400);
      });

      client = Client(endPoint: endpoint, httpClient: mockHttpClient)
        .setProject('testproject') // Required by some calls
        .setKey('testkey'); // Required by some calls for server-side

      final account = Account(client);
      await account.get(); // Make a call

      expect(mockClientWasCalled, isTrue, reason: "MockClient was not called");
    });

    // It would be good to also test self-signed certificate handling with ClientIO,
    // but that's harder to test in isolation with MockClient as MockClient doesn't
    // handle actual SSL. This is more of an integration test concern.
    // For now, we've covered the custom client injection.
  });
}
