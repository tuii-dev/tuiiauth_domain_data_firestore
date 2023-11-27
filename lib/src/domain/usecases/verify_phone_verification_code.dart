import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:tuiiauth_domain_data_firestore/src/domain/repositories/auth_repository.dart';
import 'package:tuiicore/core/errors/failure.dart';
import 'package:tuiicore/core/usecases/usecase.dart';

class VerifyPhoneVerificationCodeUseCase
    extends UseCase<bool, VerifyPhoneVerificationCodeParams> {
  final AuthRepository authRepository;

  VerifyPhoneVerificationCodeUseCase({
    required this.authRepository,
  });

  @override
  Future<Either<Failure, bool>> call(
      VerifyPhoneVerificationCodeParams params) async {
    return await authRepository.verifyPhone(params.firebaseToken, params.uid,
        params.phoneNumber, params.verificationCode);
  }
}

class VerifyPhoneVerificationCodeParams extends Equatable {
  final String firebaseToken;
  final String uid;
  final String phoneNumber;
  final String verificationCode;

  const VerifyPhoneVerificationCodeParams({
    required this.firebaseToken,
    required this.uid,
    required this.phoneNumber,
    required this.verificationCode,
  });

  @override
  List<Object?> get props {
    return [
      firebaseToken,
      uid,
      phoneNumber,
      verificationCode,
    ];
  }
}
