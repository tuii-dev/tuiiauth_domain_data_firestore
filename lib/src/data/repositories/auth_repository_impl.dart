import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:tuii_entity_models/tuii_entity_models.dart';
import 'package:tuiiauth_domain_data_firestore/src/data/datasources/firebase_auth_data_source.dart';
import 'package:tuiiauth_domain_data_firestore/src/domain/repositories/auth_repository.dart';
import 'package:tuiicore/core/enums/channel_type.dart';
// import 'package:stream_chat_flutter/stream_chat_flutter.dart' as sc;
import 'package:tuiicore/core/enums/tuii_role_type.dart';
import 'package:tuiicore/core/errors/failure.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDataSource authDataSource;
  late StreamController<UserModel?> _userStreamController;
  StreamSubscription<Future<UserModel?>>? _firestoreUserSubscription;
  StreamSubscription<UserModel?>? _firebaseUserSubscription;

  AuthRepositoryImpl({required this.authDataSource}) {
    _userStreamController = StreamController.broadcast();
    // authDataSource.firebaseUser.listen((fbUser) {
    //   _userStreamController.add(fbUser);
    // });

    // authDataSource.firestoreUser.listen((fsUser) {
    //   if (fsUser != null) {
    //     _userStreamController.add(fsUser);
    //   }
    // });
  }

  @override
  void initFirebaseUserStream() {
    _firebaseUserSubscription?.cancel();
    _firebaseUserSubscription = authDataSource.firebaseUser.listen((fbUser) {
      _userStreamController.add(fbUser);
    });
  }

  @override
  void initFirestoreUserStream({required String userId}) {
    _firestoreUserSubscription?.cancel();
    _firestoreUserSubscription = authDataSource
        .getFirestoreUserStream(userId: userId)
        .listen((firestoreUserFuture) async {
      final userModel = await firestoreUserFuture;
      if (userModel != null && !userModel.isEmpty) {
        _userStreamController.add(userModel);
      }
    });
  }

  @override
  void closeFirestoreUserStream() {
    _firestoreUserSubscription?.cancel();
  }

  @override
  Stream<UserModel?> get user => _userStreamController.stream;

  @override
  Future<Either<Failure, bool>> validateSignUpHash(
      {required String validationUrl, required String hash}) async {
    try {
      final success = await authDataSource.validateSignUpHash(
          validationUrl: validationUrl, hash: hash);

      return Right(success);
    } on Failure catch (err) {
      return Left(err);
    }
  }

  @override
  Future<Either<Failure, UserModel>> createUserWithEmailAndPassword(
      {required String email, required String password}) async {
    try {
      final user = await authDataSource.createUserWithEmailAndPassword(
          email: email, password: password);

      return Right(user);
    } on Failure catch (err) {
      return Left(err);
    }
  }

  @override
  Future<Either<Failure, UserModel>> loginWithEmailAndPassword(
      {required String email, required String password}) async {
    try {
      final user = await authDataSource.loginWithEmailAndPassword(
          email: email, password: password);

      return Right(user);
    } on Failure catch (err) {
      return Left(err);
    }
  }

  // Multifactor auth stuff
  @override
  Stream<MfaResponseModel>? initializeMfaSessionStream() {
    return authDataSource.initializeMfaSessionStream();
  }

  @override
  void closeMfaSessionStream() {
    return authDataSource.closeMfaSessionStream();
  }

  @override
  Future<void> completeMultiFactorLogin(
      auth.MultiFactorSession session, auth.PhoneMultiFactorInfo hint) {
    return authDataSource.completeMultiFactorLogin(session, hint);
  }

  @override
  Future<void> getMultiFactorVerificationCodeForEnrollment(String phoneNumber) {
    return authDataSource
        .getMultiFactorVerificationCodeForEnrollment(phoneNumber);
  }

  @override
  Future<bool> enrollUserMultiFactorAuth(
      String verificationId, String smsCode) {
    return authDataSource.enrollUserMultiFactorAuth(verificationId, smsCode);
  }

  @override
  Future<bool> unenrollUserMultiFactorAuth() {
    return authDataSource.unenrollUserMultiFactorAuth();
  }

  @override
  Future<void> getMultiFactorVerificationCodeForLogin(
      auth.MultiFactorSession session, auth.PhoneMultiFactorInfo hint) {
    return authDataSource.getMultiFactorVerificationCodeForLogin(session, hint);
  }

  @override
  Future<bool> resolveMultiFactorSignIn(
      String verificationId,
      String smsCode,
      Future<auth.UserCredential> Function(auth.MultiFactorAssertion)
          resolveSignIn) {
    return authDataSource.resolveMultiFactorSignIn(
        verificationId, smsCode, resolveSignIn);
  }

  @override
  Future<Either<Failure, UserModel>> changePassword(
      {required String currentPassword, required String newPassword}) async {
    try {
      final user = await authDataSource.changePassword(
          currentPassword: currentPassword, newPassword: newPassword);

      return Right(user);
    } on Failure catch (err) {
      return Left(err);
    }
  }

  @override
  Future<Either<Failure, bool>> logout() async {
    try {
      await authDataSource.logout();

      return const Right(true);
    } on Exception {
      return const Left(Failure());
    }
  }

  @override
  Future<Either<Failure, bool>> forceParentPinCheck(
      String parentId, bool force) async {
    try {
      await authDataSource.forceParentPinCheck(parentId, force);

      return const Right(true);
    } on Exception {
      return const Left(Failure());
    }
  }

  @override
  Future<Either<Failure, bool>> sendPasswordResetEmail(
      {required String email}) async {
    try {
      final success = await authDataSource.sendPasswordResetEmail(email: email);

      return Right(success);
    } on Failure catch (err) {
      return Left(err);
    }
  }

  @override
  Future<Either<Failure, bool>> sendEmailVerificationEmail() async {
    try {
      final success = await authDataSource.sendEmailVerificationEmail();

      return Right(success);
    } on Failure catch (err) {
      return Left(err);
    }
  }

  @override
  Future<Either<Failure, bool>> refreshFirebaseUser() async {
    try {
      final success = await authDataSource.refreshFirebaseUser();

      return Right(success);
    } on Failure catch (err) {
      return Left(err);
    }
  }

  @override
  Future<Either<Failure, bool>> getIsFirebaseUserEmailVerified() async {
    try {
      final verified = await authDataSource.getIsFirebaseUserEmailVerified();

      return Right(verified);
    } on Failure catch (err) {
      return Left(err);
    }
  }

  // @override
  // Future<Either<Failure, UserModel>> signInWithApple() async {
  //   try {
  //     final user = await authDataSource.signInWithApple();

  //     return Right(user);
  //   } on Failure catch (err) {
  //     return Left(err);
  //   }
  // }

  @override
  Future<Either<Failure, UserModel>> signInWithGoogle() async {
    try {
      final user = await authDataSource.signInWithGoogle();

      return Right(user);
    } on Failure catch (err) {
      return Left(err);
    }
  }

  @override
  Future<Either<Failure, bool>> updateUser(UserModel user, String? newEmail,
      {bool healZoom400Errors = false}) async {
    try {
      await authDataSource.updateUser(user, newEmail,
          healZoom400Errors: healZoom400Errors);

      return const Right(true);
    } on Failure catch (err) {
      return Left(err);
    }
  }

  @override
  Future<Either<Failure, bool>> updateUserPartition(
      String userId, Map<String, dynamic> user) async {
    try {
      await authDataSource.updateUserPartition(userId, user);

      return const Right(true);
    } on Failure catch (err) {
      return Left(err);
    }
  }

  @override
  Future<Either<Failure, bool>> updateEmail(String newEmail) async {
    try {
      final success = await authDataSource.updateEmail(newEmail);

      return Right(success);
    } on Failure catch (err) {
      return Left(err);
    }
  }

  @override
  Future<Either<Failure, bool>> finalizeOnboarding(
      UserModel user, String? newEmail) async {
    try {
      await authDataSource.finalizeOnboarding(user, newEmail);

      return const Right(true);
    } on Failure catch (err) {
      return Left(err);
    }
  }

  @override
  Future<Either<Failure, bool>> finalizeOnboardingForNewChild(
      UserModel user) async {
    try {
      await authDataSource.finalizeOnboardingForNewChild(user);

      return const Right(true);
    } on Failure catch (err) {
      return Left(err);
    }
  }

  @override
  Future<Either<Failure, List<SubjectModel>>> manageUserSubjects(
      String userId, TuiiRoleType role, List<String> subjectTags) async {
    try {
      final userSubjects =
          await authDataSource.manageUserSubjects(userId, role, subjectTags);

      return Right(userSubjects);
    } on Failure catch (err) {
      return Left(err);
    }
  }

  @override
  Future<Either<Failure, List<UserModel>>> searchUsers(
      TuiiRoleType role, List<String> searchTerms) async {
    try {
      final users = await authDataSource.searchUsers(role, searchTerms);

      return Right(users);
    } on Failure catch (err) {
      return Left(err);
    }
  }

  @override
  Future<Either<Failure, bool>> isDomainUnique(
      String tutorId, String domain) async {
    try {
      final unique = await authDataSource.isDomainUnique(tutorId, domain);

      return Right(unique);
    } on Failure catch (err) {
      return Left(err);
    }
  }

  @override
  Future<Either<Failure, CreateZoomTokenResponse>> getZoomToken(
      String zoomTokenUrl,
      String tutorId,
      String firebaseToken,
      String code) async {
    try {
      final response = await authDataSource.getZoomToken(
          zoomTokenUrl, tutorId, firebaseToken, code);

      return Right(response);
    } on Failure catch (err) {
      return Left(err);
    }
  }

  @override
  Future<Either<Failure, ZoomAccountDetailsModel>> getZoomAccountDetails(
      String zoomTokenUrl,
      String tutorId,
      String firebaseToken,
      String token) async {
    try {
      final response = await authDataSource.getZoomAccountDetails(
          zoomTokenUrl, tutorId, firebaseToken, token);

      return Right(response);
    } on Failure catch (err) {
      return Left(err);
    }
  }

  @override
  Future<Either<Failure, bool>> revokeZoomToken(String zoomTokenUrl,
      String tutorId, String firebaseToken, String token) async {
    try {
      final success = await authDataSource.revokeZoomToken(
          zoomTokenUrl, tutorId, firebaseToken, token);

      return Right(success);
    } on Failure catch (err) {
      return Left(err);
    }
  }

  @override
  Future<Either<Failure, String>> getStripeAccountLinkUrl(
      String firebaseToken,
      String createAccountUrl,
      String tutorId,
      String tutorEmail,
      String tutorFirstName,
      String tutorLastName,
      String tutorUrl,
      String tutorCountryCode,
      String tutorCurrencyCode) async {
    try {
      final url = await authDataSource.getStripeAccountLinkUrl(
        firebaseToken,
        createAccountUrl,
        tutorId,
        tutorEmail,
        tutorFirstName,
        tutorLastName,
        tutorUrl,
        tutorCountryCode,
        tutorCurrencyCode,
      );

      return Right(url);
    } on Failure catch (err) {
      return Left(err);
    }
  }

  @override
  Future<Either<Failure, StripeAccountDetailsModel>> getStripeAccountDetails(
      String firebaseToken,
      String getAccountDetailsUrl,
      String stripeAccountId) async {
    try {
      final accountDetails = await authDataSource.getStripeAccountDetails(
          firebaseToken, getAccountDetailsUrl, stripeAccountId);

      return Right(accountDetails);
    } on Failure catch (err) {
      return Left(err);
    }
  }

  @override
  Future<Either<Failure, bool>> isEmailUnique(String email) async {
    try {
      final isUnique = await authDataSource.isEmailUnique(email);

      return Right(isUnique);
    } on Failure catch (err) {
      return Left(err);
    }
  }

  @override
  Future<Either<Failure, List<User>>> loadAccounts(
      List<String> accountIds) async {
    try {
      final models = await authDataSource.loadAccounts(accountIds);
      final accounts = models.map((m) => User.fromModel(model: m)).toList();

      return Right(accounts);
    } on Failure catch (err) {
      return Left(err);
    }
  }

  @override
  Future<Either<Failure, List<InvitationModel>>> sendDirectConnectInvitations(
    List<InvitationModel> invitations,
    String createAppLinkUrl,
    ChannelType channel,
    String tutorId,
    String tutorFirstName,
    String tutorLastName,
  ) async {
    try {
      final failedInvites = await authDataSource.sendDirectConnectInvitations(
          invitations,
          createAppLinkUrl,
          channel,
          tutorId,
          tutorFirstName,
          tutorLastName);

      return Right(failedInvites);
    } on Failure catch (err) {
      return Left(err);
    }
  }

  @override
  String createUserEntityId() {
    return authDataSource.createUserEntityId();
  }

  @override
  Future<Either<Failure, bool>> sendPhoneVerificationSms(
      String firebasToken, String uid, String phoneNumber) async {
    try {
      final success = await authDataSource.sendPhoneVerificationSms(
          firebasToken, uid, phoneNumber);

      return Right(success);
    } on Failure catch (err) {
      return Left(err);
    }
  }

  @override
  Future<Either<Failure, bool>> verifyPhone(String firebasToken, String uid,
      String phoneNumber, String verificationCode) async {
    try {
      final success = await authDataSource.verifyPhone(
          firebasToken, uid, phoneNumber, verificationCode);

      return Right(success);
    } on Failure catch (err) {
      return Left(err);
    }
  }
}
