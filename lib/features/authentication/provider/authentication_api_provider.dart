// TODO: Implement the remote data provider for authentication.
//
// This layer is responsible for:
//   - Constructing and executing HTTP requests (via Dio + Retrofit).
//   - Returning raw response DTOs to the repository.
//   - Throwing network/HTTP-level exceptions (no business logic here).
//
// Example structure once Dio is configured:
//
//   @RestApi()
//   abstract class AuthenticationApiProvider {
//     factory AuthenticationApiProvider(Dio dio, {String baseUrl}) =
//         _AuthenticationApiProvider;
//
//     @POST('/auth/login')
//     Future<LoginResponseDto> login(@Body() LoginRequestDto body);
//   }
//
//   final authenticationApiProviderProvider =
//       Provider<AuthenticationApiProvider>((ref) {
//     final dio = ref.watch(dioProvider);
//     return AuthenticationApiProvider(dio);
//   });
