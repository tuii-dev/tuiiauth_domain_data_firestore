import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:tuii_entity_models/tuii_entity_models.dart';
import 'package:tuiicore/core/enums/channel_type.dart';
import 'package:tuiicore/core/enums/tuii_role_type.dart';
import 'package:tuiicore/core/errors/failure.dart';

abstract class AuthRepository {
  Stream<UserModel?> get user;
  void initFirebaseUserStream();
  void initFirestoreUserStream({required String userId});
  void closeFirestoreUserStream();
  Future<Either<Failure, bool>> validateSignUpHash(
      {required String validationUrl, required String hash});
  Future<Either<Failure, UserModel>> createUserWithEmailAndPassword(
      {required String email, required String password});
  Future<Either<Failure, UserModel>> loginWithEmailAndPassword(
      {required String email, required String password});
  Future<Either<Failure, UserModel>> changePassword(
      {required String currentPassword, required String newPassword});
  Future<Either<Failure, UserModel>> signInWithGoogle();
  // Future<Either<Failure, UserModel>> signInWithApple();
  Future<Either<Failure, bool>> updateUser(UserModel user, String? newEmail,
      {bool healZoom400Errors = false});
  Future<Either<Failure, bool>> updateUserPartition(
      String userId, Map<String, dynamic> user);

  Future<Either<Failure, bool>> finalizeOnboarding(
      UserModel user, String? newEmail);
  Future<Either<Failure, bool>> updateEmail(String newEmail);
  Future<Either<Failure, bool>> finalizeOnboardingForNewChild(UserModel user);
  Future<Either<Failure, bool>> logout();
  Future<Either<Failure, bool>> forceParentPinCheck(
      String parentId, bool force);
  Future<Either<Failure, bool>> sendPasswordResetEmail({required String email});
  Future<Either<Failure, bool>> sendEmailVerificationEmail();
  Future<Either<Failure, bool>> refreshFirebaseUser();
  Future<Either<Failure, bool>> getIsFirebaseUserEmailVerified();
  Future<Either<Failure, List<SubjectModel>>> manageUserSubjects(
      String userId, TuiiRoleType role, List<String> subjectTags);
  Future<Either<Failure, List<UserModel>>> searchUsers(
      TuiiRoleType role, List<String> searchTerms);
  Future<Either<Failure, bool>> isDomainUnique(String tutorId, String domain);
  Future<Either<Failure, CreateZoomTokenResponse>> getZoomToken(
      String zoomTokenUrl, String tutorId, String firebaseToken, String code);
  Future<Either<Failure, ZoomAccountDetailsModel>> getZoomAccountDetails(
      String zoomTokenUrl, String tutorId, String firebaseToken, String token);
  Future<Either<Failure, bool>> revokeZoomToken(
      String zoomTokenUrl, String tutorId, String firebaseToken, String token);
  Future<Either<Failure, String>> getStripeAccountLinkUrl(
      String firebaseToken,
      String createAccountUrl,
      String tutorId,
      String tutorEmail,
      String tutorFirstName,
      String tutorLastName,
      String tutorUrl,
      String tutorCountryCode,
      String tutorCurrencyCode);
  Future<Either<Failure, StripeAccountDetailsModel>> getStripeAccountDetails(
      String firebaseToken,
      String getAccountDetailsUrl,
      String stripeAccountId);
  Future<Either<Failure, bool>> isEmailUnique(String email);
  Future<Either<Failure, List<User>>> loadAccounts(List<String> accountIds);
  Future<Either<Failure, List<InvitationModel>>> sendDirectConnectInvitations(
    List<InvitationModel> invitations,
    String createAppLinkUrl,
    ChannelType channel,
    String tutorId,
    String tutorFirstName,
    String tutorLastName,
  );

  String createUserEntityId();

  // Multifactor auth stuff
  Stream<MfaResponseModel>? initializeMfaSessionStream();
  void closeMfaSessionStream();
  Future<void> completeMultiFactorLogin(
      auth.MultiFactorSession session, auth.PhoneMultiFactorInfo hint);
  Future<void> getMultiFactorVerificationCodeForEnrollment(String phoneNumber);
  Future<bool> enrollUserMultiFactorAuth(String verificationId, String smsCode);
  Future<bool> unenrollUserMultiFactorAuth();
  Future<void> getMultiFactorVerificationCodeForLogin(
      auth.MultiFactorSession session, auth.PhoneMultiFactorInfo hint);
  Future<bool> resolveMultiFactorSignIn(
      String verificationId,
      String smsCode,
      Future<auth.UserCredential> Function(auth.MultiFactorAssertion)
          resolveSignIn);

  // Phone verification stuff (not multi-factor)
  Future<Either<Failure, bool>> sendPhoneVerificationSms(
      String firebasToken, String uid, String phoneNumber);
  Future<Either<Failure, bool>> verifyPhone(String firebasToken, String uid,
      String phoneNumber, String verificationCode);
}
