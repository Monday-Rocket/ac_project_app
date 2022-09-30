import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AppleLoginCubit extends Cubit<String?> {
  AppleLoginCubit(super.initialState);

  Future<void> login() async {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final oAuthCredential = OAuthProvider('apple.com').credential(
      idToken: credential.identityToken,
      accessToken: credential.authorizationCode,
    );

    final authResult = await FirebaseAuth.instance.signInWithCredential(oAuthCredential);
    if (authResult.credential?.token != null) {
      emit(authResult.credential?.token.toString());
    }
  }
}
