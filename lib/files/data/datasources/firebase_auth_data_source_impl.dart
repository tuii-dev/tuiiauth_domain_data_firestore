import 'dart:async';
import 'dart:convert';
import 'dart:io';
// import 'dart:math';
import 'package:http/http.dart' as http;

import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:email_validator/email_validator.dart' as ev;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tuiicore/core/common/common.dart';
import 'package:tuiicore/core/config/paths.dart';
import 'package:tuiicore/core/errors/failure.dart';
import 'package:tuiicore/core/enums/channel_type.dart';
import 'package:tuiicore/core/enums/email_message_type.dart';
import 'package:tuiicore/core/enums/job_dispatch_type.dart';
import 'package:tuiicore/core/enums/tuii_role_type.dart';
import 'package:tuiicore/core/models/communications_job_model.dart';
import 'package:tuiicore/core/models/email_payload_model.dart';
import 'package:tuiicore/core/models/job_dispatch_model.dart';
import 'package:tuiicore/core/models/system_constants.dart';
import 'package:tuiientitymodels/files/auth/data/models/create_zoom_token_response.dart';
import 'package:tuiientitymodels/files/auth/data/models/global_subject_model.dart';
import 'package:tuiientitymodels/files/auth/data/models/global_user_subject_model.dart';
import 'package:tuiientitymodels/files/auth/data/models/invitation_model.dart';
import 'package:tuiientitymodels/files/auth/data/models/mfa_response_model.dart';
import 'package:tuiientitymodels/files/auth/data/models/onboarding_state_model.dart';
import 'package:tuiientitymodels/files/auth/data/models/send_phone_verification_code_payload.dart';
import 'package:tuiientitymodels/files/auth/data/models/send_phone_verification_sms_payload.dart';
import 'package:tuiientitymodels/files/auth/data/models/stripe_account_details_model.dart';
import 'package:tuiientitymodels/files/auth/data/models/stripe_create_account_payload_model.dart';
import 'package:tuiientitymodels/files/auth/data/models/stripe_get_account_details_payload.dart';
import 'package:tuiientitymodels/files/auth/data/models/user_model.dart';
import 'package:tuiientitymodels/files/auth/data/models/zoom_account_details_model.dart';
import 'package:tuiientitymodels/files/auth/data/models/zoom_token_payload_model.dart';
import 'package:tuiientitymodels/files/calendar/data/models/stripe_redirect_response_model.dart';
import 'package:tuiientitymodels/files/classroom/data/models/parent_home_model.dart';
import 'package:tuiientitymodels/files/classroom/data/models/student_home_model.dart';
import 'package:tuiientitymodels/files/classroom/data/models/subject_model.dart';
import 'package:tuiientitymodels/files/classroom/data/models/tutor_home_model.dart';

import 'firebase_auth_data_source.dart';

class FirebaseAuthDataSourceImpl implements FirebaseAuthDataSource {
  final auth.FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;
  final SystemConstants constants;
  // final FirebaseAnalyticsService analyticsService;
  // late StreamController<UserModel?> _firestoreUserController;

  // bool _analyticsPropsSet = false;
  auth.User? _firebaseUser;
  StreamController<MfaResponseModel>? _mfaStreamController;

  FirebaseAuthDataSourceImpl({
    required this.firebaseAuth,
    required this.firestore,
    required this.constants,
    // required this.analyticsService,
  }) {
    // _firestoreUserController = StreamController.broadcast();
  }

  @override
  Stream<UserModel?> get firebaseUser =>
      firebaseAuth.userChanges().asyncMap((auth.User? user) {
        return user != null ? _getUserModelFromFirebaseUser(user) : null;
      });

  // @override
  // Stream<UserModel?> get firestoreUser => _firestoreUserController.stream;
  @override
  Future<bool> validateSignUpHash(
      {required String validationUrl, required String hash}) async {
    try {
      final channel = constants.channel;
      final url = '$validationUrl${channel.toMap()}/$hash';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return true;
      } else {
        throw const Failure(message: 'Hash validation failed!');
      }
    } on Exception {
      throw const Failure(message: 'Hash validation failed!');
    }
  }

  @override
  Future<UserModel> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await firebaseAuth.createUserWithEmailAndPassword(
          email: email, password: password);
      final user = credential.user!;

      UserModel model = UserModel(
        id: user.uid,
        email: user.email ?? '',
        creationTimestamp: DateTime.now(),
        provider: user.providerData.first.providerId,
        emailVerified: user.emailVerified,
      );

      await firestore.collection(Paths.users).doc(user.uid).set(model.toMap());
      model = await _getUserModelFromFirebaseUser(user);

      // if (SystemConstantsProvider.runIdentityVerification == true) {
      //   await sendEmailVerificationEmail();
      // }
      // await _setAnalyticsProperties(model);
      // await analyticsService.logSignUp(
      //     providerType: IngressAuthProviderType.EmailPassword);

      model = model.copyWith(isSignUp: true);

      return model;
    } on auth.FirebaseAuthException catch (err) {
      throw Failure(
          message: 'Authentication failed: ${err.message}', code: err.code);
    } on PlatformException catch (err) {
      throw Failure(
          message: 'Authentication failed: ${err.message}', code: err.code);
    } on Exception {
      throw const Failure(
          message: 'Authentication failed: Unanticipated error',
          code: "UNANTICIPATED");
    }
  }

  @override
  Future<UserModel> loginWithEmailAndPassword(
      {required String email, required String password}) async {
    try {
      final credential = await firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
      final user = credential.user!;

      UserModel model = await _getUserModelFromFirebaseUser(user);

      // await analyticsService.logLogin(
      //     providerType: IngressAuthProviderType.EmailPassword);

      return model;
    } on auth.FirebaseAuthMultiFactorException catch (err) {
      final session = err.resolver.session;
      final hint = err.resolver.hints.first;
      final resolveSignIn = err.resolver.resolveSignIn;

      if (hint is! PhoneMultiFactorInfo) {
        throw Failure(
            // exceptionType: IngressExceptionType.FailedAuthentication,
            // providerType: IngressAuthProviderType.EmailPassword,
            message: 'Authentication failed: ${err.message}',
            code: err.code);
      } else {
        throw Failure(
          message: 'Requires multifactor auth',
          code: 'REQUIRES_MULTIFACTOR_AUTH',
          multiFactorSession: session,
          multiFactorInfo: hint,
          resolveSignIn: resolveSignIn,
          supressMessaging: true,
        );
      }
    } on auth.FirebaseAuthException catch (err) {
      throw Failure(
          // exceptionType: IngressExceptionType.FailedAuthentication,
          // providerType: IngressAuthProviderType.EmailPassword,
          message: 'Authentication failed: ${err.message}',
          code: err.code);
    } on PlatformException catch (err) {
      throw Failure(
          // exceptionType: IngressExceptionType.FailedAuthentication,
          // providerType: IngressAuthProviderType.EmailPassword,
          message: 'Authentication failed: ${err.message}',
          code: err.code);
    } on Exception {
      throw const Failure(
          message: 'Authentication failed: Unanticipated error',
          code: "UNANTICIPATED");
    }
  }

  @override
  Stream<MfaResponseModel>? initializeMfaSessionStream() {
    closeMfaSessionStream();

    _mfaStreamController = StreamController<MfaResponseModel>();

    return _mfaStreamController!.stream.asBroadcastStream();
  }

  @override
  void closeMfaSessionStream() {
    _mfaStreamController?.close();
    _mfaStreamController = null;
  }

  @override
  Future<void> completeMultiFactorLogin(
      MultiFactorSession session, PhoneMultiFactorInfo hint) async {
    if (_mfaStreamController != null) {
      try {
        await firebaseAuth.verifyPhoneNumber(
            multiFactorSession: session,
            multiFactorInfo: hint,
            verificationCompleted: (_) {
              _mfaStreamController!.sink.add(const MfaResponseModel(
                  responseType: MfaResponseType.completed, payload: ''));
            },
            verificationFailed: (FirebaseAuthException e) {
              _mfaStreamController!.sink.add(MfaResponseModel(
                  responseType: MfaResponseType.failed,
                  payload: e.message ??
                      'Failed to obtain multifactor verification code.'));
            },
            codeSent: (String verificationId, int? resendToken) {
              _mfaStreamController!.sink.add(MfaResponseModel(
                  responseType: MfaResponseType.success,
                  payload: verificationId));
            },
            codeAutoRetrievalTimeout: (String e) {
              _mfaStreamController!.sink.add(MfaResponseModel(
                  responseType: MfaResponseType.timedOut, payload: e));
            });
      } on Exception {
        throw Failure(
            message: 'Failed to obtain multifactor verification code.',
            code: 'MULTIFACTOR_VERIFICATION_FAILED');
      }
    } else {
      throw Failure(
          message:
              'Multifactor StreamController not initialized: Failed to obtain multifactor verification code.',
          code: 'MULTIFACTOR_AUTHENTICATION_FAILED');
    }
  }

  @override
  Future<void> getMultiFactorVerificationCodeForEnrollment(
      String phoneNumber) async {
    if (_mfaStreamController != null) {
      try {
        final session = await _firebaseUser!.multiFactor.getSession();
        await firebaseAuth.verifyPhoneNumber(
            phoneNumber: phoneNumber,
            multiFactorSession: session,
            verificationCompleted: (_) {
              _mfaStreamController!.sink.add(const MfaResponseModel(
                  responseType: MfaResponseType.completed, payload: ''));
            },
            verificationFailed: (FirebaseAuthException e) {
              _mfaStreamController!.sink.add(MfaResponseModel(
                  responseType: MfaResponseType.failed,
                  payload: e.message ??
                      'Failed to obtain multifactor verification code.'));
            },
            codeSent: (String verificationId, int? resendToken) {
              _mfaStreamController!.sink.add(MfaResponseModel(
                  responseType: MfaResponseType.success,
                  payload: verificationId));
            },
            codeAutoRetrievalTimeout: (String e) {
              _mfaStreamController!.sink.add(MfaResponseModel(
                  responseType: MfaResponseType.timedOut, payload: e));
            });
      } on Exception {
        throw Failure(
            message: 'Failed to obtain multifactor verification code.',
            code: 'MULTIFACTOR_VERIFICATION_FAILED');
      }
    } else {
      throw Failure(
          message:
              'Multifactor StreamController not initialized: Failed to obtain multifactor verification code.',
          code: 'MULTIFACTOR_VERIFICATION_FAILED');
    }
  }

  @override
  Future<bool> enrollUserMultiFactorAuth(
      String verificationId, String smsCode) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    try {
      await _firebaseUser!.multiFactor.enroll(
        PhoneMultiFactorGenerator.getAssertion(
          credential,
        ),
      );

      return true;
    } on FirebaseAuthException catch (e) {
      throw Failure(
          message: 'Failed to enroll user.  Message: ' + (e.message ?? ''),
          code: 'MULTIFACTOR_ENROLL_FAILED');
    }
  }

  @override
  Future<bool> unenrollUserMultiFactorAuth() async {
    try {
      final enrolledFactors =
          await _firebaseUser!.multiFactor.getEnrolledFactors();
      final multiFactorInfo = enrolledFactors.first;

      await _firebaseUser!.multiFactor
          .unenroll(multiFactorInfo: multiFactorInfo);

      return true;
    } on FirebaseAuthException catch (e) {
      throw Failure(
          message: 'Failed to unenroll user.  Message: ' + (e.message ?? ''),
          code: 'MULTIFACTOR_UNENROLL_FAILED');
    }
  }

  @override
  Future<void> getMultiFactorVerificationCodeForLogin(
      MultiFactorSession session, PhoneMultiFactorInfo hint) async {
    if (_mfaStreamController != null) {
      try {
        await firebaseAuth.verifyPhoneNumber(
            multiFactorSession: session,
            multiFactorInfo: hint,
            verificationCompleted: (_) {
              _mfaStreamController!.sink.add(const MfaResponseModel(
                  responseType: MfaResponseType.completed, payload: ''));
            },
            verificationFailed: (FirebaseAuthException e) {
              _mfaStreamController!.sink.add(MfaResponseModel(
                  responseType: MfaResponseType.failed,
                  payload: e.message ??
                      'Failed to obtain multifactor verification code.'));
            },
            codeSent: (String verificationId, int? resendToken) {
              _mfaStreamController!.sink.add(MfaResponseModel(
                  responseType: MfaResponseType.success,
                  payload: verificationId));
            },
            codeAutoRetrievalTimeout: (String e) {
              _mfaStreamController!.sink.add(MfaResponseModel(
                  responseType: MfaResponseType.timedOut, payload: e));
            });
      } on Exception {
        throw Failure(
            message: 'Failed to obtain multifactor verification code.',
            code: 'MULTIFACTOR_VERIFICATION_FAILED');
      }
    } else {
      throw Failure(
          message:
              'Multifactor StreamController not initialized: Failed to obtain multifactor verification code.',
          code: 'MULTIFACTOR_VERIFICATION_FAILED');
    }
  }

  @override
  Future<bool> resolveMultiFactorSignIn(
      String verificationId,
      String smsCode,
      Future<UserCredential> Function(MultiFactorAssertion)
          resolveSignIn) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    try {
      await resolveSignIn(
        PhoneMultiFactorGenerator.getAssertion(
          credential,
        ),
      );

      return true;
    } on FirebaseAuthException catch (e) {
      throw Failure(
          message: 'Login failed.  Message: ' + (e.message ?? ''),
          code: 'MULTIFACTOR_LOGIN_FAILED');
    }
  }

  @override
  Future<UserModel> changePassword(
      {required String currentPassword, required String newPassword}) async {
    try {
      final email = _firebaseUser!.email!;
      final credential = await firebaseAuth.signInWithEmailAndPassword(
          email: email, password: currentPassword);

      final user = credential.user!;
      await user.updatePassword(newPassword);

      UserModel model = await _getUserModelFromFirebaseUser(user);

      // await analyticsService.logLogin(
      //     providerType: IngressAuthProviderType.EmailPassword);

      return model;
    } on auth.FirebaseAuthException catch (err) {
      throw Failure(
          // exceptionType: IngressExceptionType.FailedAuthentication,
          // providerType: IngressAuthProviderType.EmailPassword,
          message: 'Authentication failed: ${err.message}',
          code: err.code);
    } on PlatformException catch (err) {
      throw Failure(
          // exceptionType: IngressExceptionType.FailedAuthentication,
          // providerType: IngressAuthProviderType.EmailPassword,
          message: 'Authentication failed: ${err.message}',
          code: err.code);
    } on Exception {
      throw const Failure(
          // exceptionType: IngressExceptionType.FailedAuthentication,
          // providerType: IngressAuthProviderType.EmailPassword,
          message: 'Password change failed',
          code: 'CHANGE_PASSWORD_FAILED');
    }
  }

  @override
  Future<bool> sendEmailVerificationEmail() async {
    try {
      await _firebaseUser!.sendEmailVerification();

      return true;
    } on auth.FirebaseAuthException catch (err) {
      throw Failure(
          // exceptionType: IngressExceptionType.FailedResetPassword,
          // providerType: IngressAuthProviderType.EmailPassword,
          message: err.message,
          code: err.code);
    }
  }

  @override
  Future<bool> refreshFirebaseUser() async {
    try {
      await _firebaseUser!.reload();
      return true;
    } on auth.FirebaseAuthException catch (err) {
      throw Failure(
          // exceptionType: IngressExceptionType.FailedResetPassword,
          // providerType: IngressAuthProviderType.EmailPassword,
          message: err.message,
          code: err.code);
    }
  }

  @override
  Future<bool> getIsFirebaseUserEmailVerified() async {
    return await _firebaseUser!.reload().then((value) {
      final user = FirebaseAuth.instance.currentUser;
      final verified = user?.emailVerified ?? false;
      return verified;
    });
  }

  @override
  Future<bool> sendPasswordResetEmail({required String email}) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email);

      return true;
    } on auth.FirebaseAuthException catch (err) {
      throw Failure(
          // exceptionType: IngressExceptionType.FailedResetPassword,
          // providerType: IngressAuthProviderType.EmailPassword,
          message: err.message,
          code: err.code);
    }
  }

  @override
  Future<void> logout() async {
    return await firebaseAuth.signOut();
  }

  @override
  Future<void> forceParentPinCheck(String parentId, bool force) async {
    final result = await firestore
        .collection(Paths.users)
        .doc(parentId)
        .set({'forceParentPinCheck': force}, SetOptions(merge: true));

    return result;
  }

  // @override
  // Future<UserModel> signInWithApple() async {
  //   try {
  //     // To prevent replay attacks with the credential returned from Apple, we
  //     // include a nonce in the credential request. When signing in with
  //     // Firebase, the nonce in the id token returned by Apple, is expected to
  //     // match the sha256 hash of `rawNonce`.
  //     final rawNonce = _generateNonce();
  //     final nonce = _sha256ofString(rawNonce);

  //     // Request credential for the currently signed in Apple account.
  //     final appleCredential = await SignInWithApple.getAppleIDCredential(
  //       scopes: [
  //         AppleIDAuthorizationScopes.email,
  //         AppleIDAuthorizationScopes.fullName,
  //       ],
  //       nonce: nonce,
  //     );
  //     final oAuthCredential = OAuthProvider("apple.com").credential(
  //       idToken: appleCredential.identityToken,
  //       rawNonce: rawNonce,
  //     );
  //     // Once signed in, return the UserCredential
  //     final credential =
  //         await FirebaseAuth.instance.signInWithCredential(oAuthCredential);
  //     final user = credential.user!;

  //     UserModel model = await _getUserModelFromFirebaseUser(user);

  //     if (model.isEmpty) {
  //       UserModel model = UserModel.fromMap({
  //         'id': user.uid,
  //         'email': user.email,
  //         'emailVerified': true,
  //         'phoneVerified': true,
  //         'creationTimestamp': DateTime.now(),
  //         'provider': user.providerData.first.providerId,
  //       });

  //       await firestore
  //           .collection(Paths.users)
  //           .doc(user.uid)
  //           .set(model.toMap());

  //       // await _setAnalyticsProperties(model);
  //       // await analyticsService.logSignUp(
  //       //     providerType: IngressAuthProviderType.Apple);

  //       model = model.copyWith(isSignUp: true);
  //     } else {
  //       // await analyticsService.logLogin(
  //       //     providerType: IngressAuthProviderType.Apple);
  //     }
  //     return model;
  //   } on auth.FirebaseAuthException catch (err) {
  //     throw Failure(
  //         // exceptionType: IngressExceptionType.FailedAuthentication,
  //         // providerType: IngressAuthProviderType.Apple,
  //         message: 'Authentication failed: ${err.message}',
  //         code: err.code);
  //   } on PlatformException catch (err) {
  //     throw Failure(
  //         // exceptionType: IngressExceptionType.FailedAuthentication,
  //         // providerType: IngressAuthProviderType.Apple,
  //         message: 'Authentication failed: ${err.message}',
  //         code: err.code);
  //   } on SignInWithAppleAuthorizationException {
  //     throw const Failure(
  //         // exceptionType: IngressExceptionType.FailedAuthentication,
  //         // providerType: IngressAuthProviderType.Apple,
  //         message: 'Authentication failed: User canceled',
  //         code: 'IngressException',
  //         supressMessaging: true);
  //   } on Exception {
  //     throw const Failure(
  //       // exceptionType: IngressExceptionType.FailedAuthentication,
  //       // providerType: IngressAuthProviderType.Apple,
  //       message: 'Authentication failed: Unanticipated',
  //       code: 'IngressException',
  //     );
  //   }
  // }

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      String firstName = '';
      String lastName = '';
      String profileImageUrl = '';
      if (googleUser != null) {
        if (googleUser.displayName != null) {
          final nameParts = googleUser.displayName!.split(' ');
          firstName = nameParts[0];
          lastName = nameParts.sublist(1).join(' ');
          profileImageUrl = googleUser.photoUrl ?? '';
        }
        // Obtain the auth details from the request
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        // Create a new credential
        final oAuthCredential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Once signed in, return the UserCredential
        final credential =
            await FirebaseAuth.instance.signInWithCredential(oAuthCredential);
        final user = credential.user!;

        UserModel model = await _getUserModelFromFirebaseUser(user);

        if (model.isEmpty) {
          UserModel newModel = UserModel.fromMap({
            'id': model.id,
            'email': model.email,
            // 'emailVerified': false,
            // 'phoneVerified': false,
            'creationTimestamp': DateTime.now().toUtc().millisecondsSinceEpoch,
            'firstName': firstName,
            'lastName': lastName,
            'profileImageUrl': profileImageUrl,
            'provider': model.provider,
          });

          await firestore
              .collection(Paths.users)
              .doc(user.uid)
              .set(newModel.toMap());

          // await _setAnalyticsProperties(model);
          // await analyticsService.logSignUp(
          //     providerType: IngressAuthProviderType.Google);

          return newModel.copyWith(
              firebaseToken: model.firebaseToken, isSignUp: true);
        } else {
          // await analyticsService.logLogin(
          //     providerType: IngressAuthProviderType.Google);
        }
        return model;
      }

      throw const Failure(message: 'User canceled', supressMessaging: true);
    } on auth.FirebaseAuthMultiFactorException catch (err) {
      final session = err.resolver.session;
      final hint = err.resolver.hints.first;
      final resolveSignIn = err.resolver.resolveSignIn;

      if (hint is! PhoneMultiFactorInfo) {
        throw Failure(
            // exceptionType: IngressExceptionType.FailedAuthentication,
            // providerType: IngressAuthProviderType.EmailPassword,
            message: 'Authentication failed: ${err.message}',
            code: err.code);
      } else {
        throw Failure(
          message: 'Requires multifactor auth',
          code: 'REQUIRES_MULTIFACTOR_AUTH',
          multiFactorSession: session,
          multiFactorInfo: hint,
          resolveSignIn: resolveSignIn,
          supressMessaging: true,
        );
      }
    } on auth.FirebaseAuthException catch (err) {
      throw Failure(
          // exceptionType: IngressExceptionType.FailedAuthentication,
          // providerType: IngressAuthProviderType.Google,
          message: 'Authentication failed: ${err.message}',
          code: err.code);
    } on PlatformException catch (err) {
      throw Failure(
          // exceptionType: IngressExceptionType.FailedAuthentication,
          // providerType: IngressAuthProviderType.Google,
          message: 'Authentication failed: ${err.message}',
          code: err.code);
    } on Exception {
      throw const Failure(
        // exceptionType: IngressExceptionType.FailedAuthentication,
        // providerType: IngressAuthProviderType.Google,
        message: 'Authentication failed: Unanticipated',
        code: 'IngressException',
      );
    }
  }

  @override
  Future<void> updateUser(UserModel user, String? newEmail,
      {bool healZoom400Errors = false}) async {
    if (newEmail != null && newEmail.isNotEmpty && user.email != newEmail) {
      if (ev.EmailValidator.validate(newEmail)) {
        await firebaseAuth.currentUser!.reload();
        final firebaseUser = firebaseAuth.currentUser!;
        await firebaseUser.updateEmail(newEmail);
        user = user.copyWith(email: newEmail);
      }
    }

    return firestore
        .collection(Paths.users)
        .doc(user.id)
        .set(user.toMap(), SetOptions(merge: true));
  }

  @override
  Future<void> updateUserPartition(
      String userId, Map<String, dynamic> user) async {
    return firestore
        .collection(Paths.users)
        .doc(userId)
        .set(user, SetOptions(merge: true));
  }

  @override
  Future<bool> updateEmail(String newEmail) async {
    if (ev.EmailValidator.validate(newEmail)) {
      await firebaseAuth.currentUser!.reload();
      final firebaseUser = firebaseAuth.currentUser!;
      await firebaseUser.updateEmail(newEmail);

      return true;
    } else {
      return false;
    }
  }

  @override
  Future<void> finalizeOnboarding(UserModel user, String? newEmail) async {
    if (newEmail != null && newEmail.isNotEmpty && user.email != newEmail) {
      final success = await updateEmail(newEmail);
      if (success == true) {
        user = user.copyWith(email: newEmail);
      }
    }

    final docRef = await firestore.collection(Paths.users).doc(user.id).get();
    final existingUser = UserModel.fromMap(docRef.data()!);

    if (existingUser.isStripeSetUpComplete == true) {
      user = user.copyWith(
        isStripeSetUpComplete: true,
        stripeAccountId: existingUser.stripeAccountId,
        stripeAccountDashboardUrl: existingUser.stripeAccountDashboardUrl,
      );
    }

    await firestore
        .collection(Paths.users)
        .doc(user.id)
        .set(user.toMap(), SetOptions(merge: true));
    // _bindToFirestoreUser(user.id!);

    if (user.roleType == TuiiRoleType.tutor) {
      final tutorHomeDoc = TutorHomeModel(
        id: user.id!,
        tutorId: user.id!,
        classrooms: const [],
      );

      await firestore
          .collection(Paths.tutorHome)
          .doc(user.id)
          .set(tutorHomeDoc.toMap());
    } else if (user.roleType == TuiiRoleType.student) {
      final studentHomeDoc = StudentHomeModel(
        id: user.id!,
        studentId: user.id!,
        classrooms: const [],
      );

      await firestore
          .collection(Paths.studentHome)
          .doc(user.id)
          .set(studentHomeDoc.toMap());
    } else if (user.roleType == TuiiRoleType.parent) {
      final parentHomeDoc = ParentHomeModel(
        id: user.id!,
        parentId: user.id!,
        tutorConnections: const [],
      );

      await firestore
          .collection(Paths.parentHome)
          .doc(user.id)
          .set(parentHomeDoc.toMap());
    }

    Future.delayed(const Duration(milliseconds: 1000), () async {
      await refreshFirebaseUser();
    });
  }

  @override
  Future<void> finalizeOnboardingForNewChild(UserModel user) async {
    if (user.roleType == TuiiRoleType.student) {
      final studentHomeDoc = StudentHomeModel(
        id: user.id!,
        studentId: user.id!,
        classrooms: const [],
      );

      await firestore
          .collection(Paths.studentHome)
          .doc(user.id)
          .set(studentHomeDoc.toMap());
    }
  }

  @override
  Future<List<SubjectModel>> manageUserSubjects(
      String userId, TuiiRoleType role, List<String> subjectTags) async {
    List<SubjectModel> subjects = [];
    for (int i = 0; i < subjectTags.length; i++) {
      final tag = subjectTags[i];
      final subject = await _getGlobalSubject(userId, tag);
      if (subject != null) {
        GlobalUserSubjectModel userSubject =
            GlobalUserSubjectModel.init(userId, role, subject);
        final docRef = firestore.collection(Paths.userSubjects).doc();
        userSubject = userSubject.copyWith(id: docRef.id);

        await docRef.set(userSubject.toMap());
        subjects.add(userSubject.toSubjectModel());
      }
    }

    return subjects;
  }

  @override
  Future<List<UserModel>> searchUsers(
      TuiiRoleType roleType, List<String> searchTerms) async {
    final searchRole = roleType == TuiiRoleType.tutor ? 'tutor' : 'student';

    return await firestore
        .collection(Paths.users)
        .where('roleType', isEqualTo: searchRole)
        .where('searchTerms', arrayContainsAny: searchTerms)
        .get()
        .then((docs) {
      if (docs.size > 0) {
        return docs.docs.map((snap) => UserModel.fromSnapshot(snap)).toList();
      } else {
        return [];
      }
    });
  }

  @override
  Future<bool> isDomainUnique(String tutorId, String domain) async {
    return await firestore
        .collection(Paths.users)
        .where('id', isNotEqualTo: tutorId)
        .where('domain', isEqualTo: domain.toLowerCase())
        .get()
        .then((docs) {
      return docs.size == 0;
    });
  }

  @override
  Future<CreateZoomTokenResponse> getZoomToken(String zoomTokenUrl,
      String tutorId, String firebaseToken, String code) async {
    final channel = constants.channel;
    final encodedCode = encodeBase64(code);
    final url =
        Uri.parse('$zoomTokenUrl$tutorId/$encodedCode/${channel.toMap()}');
    debugPrint('Firebase token: $firebaseToken');
    final response = await http.get(url, headers: {
      HttpHeaders.authorizationHeader: 'Bearer $firebaseToken',
    });

    if (response.statusCode == 200) {
      return CreateZoomTokenResponse.fromMap(json.decode(response.body));
    } else {
      throw Failure(message: 'Failed to create zoom token.');
    }
  }

  @override
  Future<ZoomAccountDetailsModel> getZoomAccountDetails(String zoomAccountUrl,
      String tutorId, String firebaseToken, String token) async {
    debugPrint('Firebase token: $firebaseToken');
    final url = Uri.parse(zoomAccountUrl);
    final payload = ZoomTokenPayloadModel(tutorId: tutorId, token: token);

    final response = await http.post(url,
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.authorizationHeader: 'Bearer $firebaseToken',
        },
        body: payload.toJson());

    if (response.statusCode == 200) {
      return ZoomAccountDetailsModel.fromMap(json.decode(response.body));
    } else {
      throw Failure(message: 'Failed to create zoom token.');
    }
  }

  @override
  Future<bool> revokeZoomToken(String zoomTokenUrl, String tutorId,
      String firebaseToken, String token) async {
    debugPrint('Firebase token: $firebaseToken');
    final url = Uri.parse(zoomTokenUrl);

    final payload = ZoomTokenPayloadModel(tutorId: tutorId, token: token);
    final response = await http.post(
      url,
      headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.authorizationHeader: 'Bearer $firebaseToken',
      },
      body: payload.toJson(),
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      throw Failure(message: 'Failed to revoke zoom token.');
    }
  }

  @override
  Stream<Future<UserModel>> getFirestoreUserStream({required String userId}) {
    try {
      return firestore
          .collection(Paths.users)
          .doc(userId)
          .snapshots()
          .map((snap) async {
        if (snap.exists) {
          final token = await _firebaseUser?.getIdToken();
          var user = UserModel.fromSnapshot(snap);
          // if (user.phoneVerified != true && user.provider != 'password') {
          //   user = user.copyWith(
          //       firebaseToken: token,
          //       phoneVerified: true,
          //       phoneNumber: 'oauth');
          // } else {
          //   user = user.copyWith(firebaseToken: token);
          // }
          user = user.copyWith(firebaseToken: token);

          return user;
        } else {
          return UserModel.empty();
        }
      });
    } on FirebaseException catch (e) {
      debugPrint(e.message);
      throw const Failure(message: 'Failed to get firestore user stream');
    } on Exception {
      throw const Failure(message: 'Failed to get firestore user stream');
    }
  }

  @override
  Future<String> getStripeAccountLinkUrl(
      String firebaseToken,
      String createAccountUrl,
      String tutorId,
      String tutorEmail,
      String tutorFirstName,
      String tutorLastName,
      String tutorUrl,
      String tutorCountryCode,
      String tutorCurrencyCode) async {
    final url = Uri.parse(createAccountUrl);
    debugPrint('Firebase token: $firebaseToken');

    final payload = StripeCreateAccountPayloadModel(
      tutorId: tutorId,
      tutorEmail: tutorEmail,
      tutorFirstName: tutorFirstName,
      tutorLastName: tutorLastName,
      tutorUrl: tutorUrl,
      tutorCountryCode: tutorCountryCode,
      tutorCurrencyCode: tutorCurrencyCode,
      channel: constants.channel,
    );

    final res = await http.post(url,
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.authorizationHeader: 'Bearer $firebaseToken',
        },
        body: payload.toJson());
    final sessionResponse = StripeRedirectResponse.fromJson(res.body);

    return sessionResponse.url ?? '';
  }

  @override
  Future<StripeAccountDetailsModel> getStripeAccountDetails(
      String firebaseToken,
      String getAccountDetailsUrl,
      String stripeAccountId) async {
    final url = Uri.parse(getAccountDetailsUrl);
    debugPrint('Firebase token: $firebaseToken');

    final payload = StripeGetAccountDetailsPayload(
      accountId: stripeAccountId,
    );

    final res = await http.post(url,
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.authorizationHeader: 'Bearer $firebaseToken',
        },
        body: payload.toJson());
    final accountDetails = StripeAccountDetailsModel.fromJson(res.body);

    return accountDetails;
  }

  @override
  Future<bool> isEmailUnique(String email) async {
    final docs = await firestore
        .collection(Paths.users)
        .where('email', isEqualTo: email)
        .get();

    return docs.size == 0;
  }

  @override
  Future<List<UserModel>> loadAccounts(List<String> accountIds) async {
    List<UserModel> models = [];
    final refs = accountIds
        .map((id) => firestore.collection(Paths.users).doc(id))
        .toList();

    for (int i = 0; i < refs.length; i++) {
      final user = await refs[i].get().then((snap) async {
        if (snap.exists) {
          final token = await _firebaseUser?.getIdToken();
          var user = UserModel.fromSnapshot(snap);
          return user = user.copyWith(firebaseToken: token);
        }
      });

      if (user != null) {
        models.add(user);
      }
    }

    return models;
  }

  @override
  Future<List<InvitationModel>> sendDirectConnectInvitations(
    List<InvitationModel> invitations,
    String createAppLinkUrl,
    ChannelType channel,
    String tutorId,
    String tutorFirstName,
    String tutorLastName,
  ) async {
    List<InvitationModel> failedInvites = [];

    for (int i = 0; i < invitations.length; i++) {
      final invite = invitations[i];
      String directConnectUrl = _getDirectConnectAppLinkUrlForChannel(
          channel,
          createAppLinkUrl,
          tutorId,
          invite.email!,
          invite.firstName ?? '',
          invite.lastName ?? '');
      final url = Uri.parse(directConnectUrl);
      final response = await http.get(url);

      if (response.statusCode == 201) {
        final body = json.decode(response.body);
        final appLink = body['appLink'];
        debugPrint('AppLink Url: $appLink');
        final job = JobDispatchModel(
            jobType: JobDispatchType.sendCommunications,
            payload: CommunicationsJobModel(
                sendEmail: true,
                sendSms: false,
                emailPayload: EmailPayloadModel(
                    toAddresses: [invite.email!],
                    emailType: EmailMessageType.connectionInvitationRequest,
                    attachments: const [],
                    substitutions: {
                      'student_first_name': invite.firstName ?? 'there',
                      'student_last_name': invite.lastName ?? '',
                      'tutor_first_name': tutorFirstName,
                      'tutor_last_name': tutorLastName,
                      'direct_connect_url': appLink,
                    })));

        await firestore.collection(Paths.jobDispatch).add(job.toMap());
      } else {
        failedInvites.add(invite);
      }
    }

    return failedInvites;
  }

  @override
  Future<bool> sendPhoneVerificationSms(
      String firebaseToken, String uid, String phoneNumber) async {
    final smsSendPhoneVerificationCodeUrl =
        constants.smsSendPhoneVerificationCodeUrl;
    final url = Uri.parse(smsSendPhoneVerificationCodeUrl);
    final payload =
        SendPhoneVerificationSmsPayloadModel(to: phoneNumber, uid: uid);

    final response = await http.post(url,
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.authorizationHeader: 'Bearer $firebaseToken',
        },
        body: payload.toJson());

    if (response.statusCode != 200) {
      throw Failure(message: 'Failed to send phone verification sms.');
    }

    return true;
  }

  @override
  Future<bool> verifyPhone(String firebaseToken, String uid, String phoneNumber,
      String verificationCode) async {
    final smsVerifyPhoneVerificationCodeUrl =
        constants.smsVerifyPhoneVerificationCodeUrl;
    final url = Uri.parse(smsVerifyPhoneVerificationCodeUrl);
    final payload = SendPhoneVerificationCodePayloadModel(
        uid: uid, phoneNumber: phoneNumber, code: verificationCode);

    final response = await http.post(url,
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.authorizationHeader: 'Bearer $firebaseToken',
        },
        body: payload.toJson());

    if (response.statusCode != 200) {
      throw Failure(message: 'Invalid code specified.');
    }

    return true;
  }

  @override
  String createUserEntityId() {
    final docRef = firestore.collection(Paths.users).doc();

    return docRef.id;
  }
  // @override
  // Future<void> revokeZoomToken(String zoomTokenUrl, String token) async {
  //   final url = Uri.parse(zoomTokenUrl + '$code');
  //   final response = await http.get(url);

  //   if (response.statusCode == 200) {
  //     return ZoomTokenModel.fromMap(json.decode(response.body));
  //   } else {
  //     throw Failure(message: 'Failed to create zoom token.');
  //   }
  // }

  // Future<bool> _firestoreDocExists(String collectionPath, String docId) async {
  //   try {
  //     var doc = await firestore.collection(collectionPath).doc(docId).get();
  //     return doc.exists;
  //   } catch (e) {
  //     return false;
  //   }
  // }

  String _getDirectConnectAppLinkUrlForChannel(
    ChannelType channel,
    String appLinkUrlStub,
    String tutorId,
    String learnerEmail,
    String learnerFirstName,
    String learnerLastName,
  ) {
    String url = appLinkUrlStub;
    switch (constants.channel) {
      case ChannelType.beta:
        url +=
            'create/beta/directconnect/$tutorId/?learnerEmail=$learnerEmail&learnerFirstName=$learnerFirstName&learnerLastName=$learnerLastName';
        break;
      case ChannelType.alpha:
        url +=
            'create/alpha/directconnect/$tutorId/?learnerEmail=$learnerEmail&learnerFirstName=$learnerFirstName&learnerLastName=$learnerLastName';
        break;
      case ChannelType.app:
        url +=
            'create/directconnect/$tutorId/?learnerEmail=$learnerEmail&learnerFirstName=$learnerFirstName&learnerLastName=$learnerLastName';
        break;
      default:
        url +=
            'create/dev/directconnect/$tutorId/?learnerEmail=$learnerEmail&learnerFirstName=$learnerFirstName&learnerLastName=$learnerLastName';
        break;
    }

    return url;
  }

  Future<UserModel> _getUserModelFromFirebaseUser(
      auth.User firebaseUser) async {
    try {
      _firebaseUser = firebaseUser; // firebaseUser;
      final provider = firebaseUser.providerData[0].providerId;
      final token = await firebaseUser.getIdToken();
      final email = provider == "google.com"
          ? firebaseUser.providerData[0].email
          : firebaseUser.email;

      final emailVerified = provider == "google.com" ? true : null;
      final multiFactor = firebaseUser.multiFactor;

      final doc =
          await firestore.collection(Paths.users).doc(firebaseUser.uid).get();
      UserModel user = UserModel.fromSnapshot(doc);
      user = user.copyWith(
        id: firebaseUser.uid,
        firebaseToken: token,
        email: email,
        emailVerified: emailVerified,
        multiFactor: multiFactor,
        provider: provider,
      );
      if (!user.isEmpty && (user.id != null && user.id!.isNotEmpty)) {
        // Existing user
        // if ((user.emailVerified != emailVerified) &&
        //     SystemConstantsProvider.runIdentityVerification == true) {
        //   ProfileCompletionModel? profileCompletion;
        //   if (user.onboardingState?.profileCompletion != null) {
        //     profileCompletion = user.onboardingState!.profileCompletion!
        //         .copyWith(emailVerified: emailVerified);
        //   } else {
        //     profileCompletion = ProfileCompletionModel.fromUser(user);
        //     profileCompletion =
        //         profileCompletion.copyWith(emailVerified: emailVerified);
        //   }
        //   final onboardingState = user.onboardingState != null
        //       ? user.onboardingState!
        //           .copyWith(profileCompletion: profileCompletion)
        //       : OnboardingStateModel(profileCompletion: profileCompletion);
        //   user = user.copyWith(
        //       emailVerified: emailVerified,
        //       profilePercentageComplete: profileCompletion
        //           .getProfileCompletionPercentage(user.roleType!),
        //       onboardingState: onboardingState);

        //   firestore
        //       .collection(Paths.users)
        //       .doc(firebaseUser.uid)
        //       .set(user.toMap(), SetOptions(merge: true));
        // } else {
        if (user.isStripeSetUpComplete == true) {
          var profileCompletion = user.onboardingState?.profileCompletion;
          if (profileCompletion != null && profileCompletion.payments != true) {
            profileCompletion = user.onboardingState!.profileCompletion!
                .copyWith(payments: true);

            final onboardingState = user.onboardingState != null
                ? user.onboardingState!
                    .copyWith(profileCompletion: profileCompletion)
                : OnboardingStateModel(profileCompletion: profileCompletion);
            user = user.copyWith(
                profilePercentageComplete: profileCompletion!
                    .getProfileCompletionPercentage(user.roleType!),
                onboardingState: onboardingState);

            firestore
                .collection(Paths.users)
                .doc(firebaseUser.uid)
                .set(user.toMap(), SetOptions(merge: true));
          }
        }
        // }
      } else {
        // Brand new user, just signed up and onboarding
        final parts = firebaseUser.displayName != null &&
                firebaseUser.displayName!.isNotEmpty
            ? firebaseUser.displayName!.split(' ')
            : null;
        user = user.copyWith(
          id: firebaseUser.uid,
          email: email,
          // emailVerified: emailVerified,
          firstName: parts != null ? parts[0] : '',
          lastName: parts != null ? parts[1] : '',
          profileImageUrl: firebaseUser.photoURL,
          // provider: firebaseUser.providerData[0].providerId,
          isEmpty: true,
        );
      }

      // if (!_analyticsPropsSet && user.id != null && user.id!.isNotEmpty) {
      //   await _setAnalyticsProperties(user);
      // }

      return user;
    } on Exception {
      // debugPrint(err.toString());
      return UserModel.empty();
    }
  }

  // Future<void> _setAnalyticsProperties(UserModel user) {
  //   _analyticsPropsSet = true;

  //   return analyticsService
  //       .setUserProperties(userId: user.id!, properties: {'email': user.email});
  // }

  Future<GlobalSubjectModel?> _getGlobalSubject(
      String userId, String subjectTag) async {
    try {
      final key = subjectTag.toLowerCase().replaceAll(' ', '');
      final doc = await firestore
          .collection(Paths.subjects)
          .where('key', isEqualTo: key)
          .get();

      if (doc.size > 0) {
        return GlobalSubjectModel.fromMap(doc.docs.first.data());
      } else {
        GlobalSubjectModel subject =
            GlobalSubjectModel.init(userId, subjectTag);

        final docRef = firestore.collection(Paths.subjects).doc();
        subject = subject.copyWith(id: docRef.id);

        await docRef.set(subject.toMap());

        return subject;
      }
    } on Exception {
      // debugPrint(err.toString());
      return null;
    }
  }

  // String _generateNonce([int length = 32]) {
  //   const charset =
  //       '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
  //   final random = Random.secure();
  //   return List.generate(length, (_) => charset[random.nextInt(charset.length)])
  //       .join();
  // }

  /// Returns the sha256 hash of [input] in hex notation.
  // String _sha256ofString(String input) {
  //   final bytes = utf8.encode(input);
  //   final digest = sha256.convert(bytes);
  //   return digest.toString();
  // }
}
