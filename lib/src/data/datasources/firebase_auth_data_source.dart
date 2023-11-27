import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:tuii_entity_models/tuii_entity_models.dart';
import 'package:tuiicore/core/enums/channel_type.dart';
import 'package:tuiicore/core/enums/tuii_role_type.dart';

abstract class FirebaseAuthDataSource {
  Stream<UserModel?> get firebaseUser;
  // Stream<UserModel?> get firestoreUser;
  Future<bool> validateSignUpHash(
      {required String validationUrl, required String hash});
  Future<UserModel> createUserWithEmailAndPassword({
    required String email,
    required String password,
  });
  Future<UserModel> loginWithEmailAndPassword(
      {required String email, required String password});
  Stream<MfaResponseModel>? initializeMfaSessionStream();
  void closeMfaSessionStream();
  Future<void> completeMultiFactorLogin(
      MultiFactorSession session, PhoneMultiFactorInfo hint);
  Future<void> getMultiFactorVerificationCodeForEnrollment(String phoneNumber);
  Future<bool> enrollUserMultiFactorAuth(String verificationId, String smsCode);
  Future<bool> unenrollUserMultiFactorAuth();
  Future<UserModel> changePassword(
      {required String currentPassword, required String newPassword});
  Future<void> getMultiFactorVerificationCodeForLogin(
      MultiFactorSession session, PhoneMultiFactorInfo hint);
  Future<bool> resolveMultiFactorSignIn(String verificationId, String smsCode,
      Future<UserCredential> Function(MultiFactorAssertion) resolveSignIn);
  Future<UserModel> signInWithGoogle();
  // Future<UserModel> signInWithApple();
  Future<void> updateUser(UserModel user, String? newEmail,
      {bool healZoom400Errors = false});
  Future<void> updateUserPartition(String userId, Map<String, dynamic> user);
  Future<void> logout();
  Future<void> forceParentPinCheck(String parentId, bool force);
  Future<bool> sendPasswordResetEmail({required String email});
  Future<bool> refreshFirebaseUser();
  Future<bool> getIsFirebaseUserEmailVerified();
  Future<bool> sendEmailVerificationEmail();
  Future<List<SubjectModel>> manageUserSubjects(
      String userId, TuiiRoleType role, List<String> subjectTags);
  Future<bool> updateEmail(String newEmail);
  Future<void> finalizeOnboarding(UserModel user, String? newEmail);
  Future<void> finalizeOnboardingForNewChild(UserModel user);
  Future<List<UserModel>> searchUsers(
      TuiiRoleType roleType, List<String> searchTerms);
  Future<bool> isDomainUnique(String tutorId, String domain);
  Future<CreateZoomTokenResponse> getZoomToken(
      String zoomTokenUrl, String tutorId, String firebaseToken, String code);
  Future<ZoomAccountDetailsModel> getZoomAccountDetails(
      String zoomTokenUrl, String tutorId, String firebaseToken, String token);
  Future<bool> revokeZoomToken(
      String zoomTokenUrl, String tutorId, String firebaseToken, String token);
  Stream<Future<UserModel?>> getFirestoreUserStream({required String userId});
  Future<String> getStripeAccountLinkUrl(
      String firebaseToken,
      String createAccountUrl,
      String tutorId,
      String tutorEmail,
      String tutorFirstName,
      String tutorLastName,
      String tutorUrl,
      String tutorCountryCode,
      String tutorCurrencyCode);

  Future<StripeAccountDetailsModel> getStripeAccountDetails(
      String firebaseToken,
      String getAccountDetailsUrl,
      String stripeAccountId);

  Future<bool> isEmailUnique(String email);
  Future<List<UserModel>> loadAccounts(List<String> accountIds);
  Future<List<InvitationModel>> sendDirectConnectInvitations(
    List<InvitationModel> invitations,
    String createAppLinkUrl,
    ChannelType channel,
    String tutorId,
    String tutorFirstName,
    String tutorLastName,
  );
  Future<bool> sendPhoneVerificationSms(
      String firebasToken, String uid, String phoneNumber);
  Future<bool> verifyPhone(String firebasToken, String uid, String phoneNumber,
      String verificationCode);
  String createUserEntityId();
}
