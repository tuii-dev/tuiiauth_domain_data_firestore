import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:tuiiauth_domain_data_firestore/src/domain/repositories/auth_repository.dart';
import 'package:tuiicore/core/errors/failure.dart';
import 'package:tuiicore/core/usecases/usecase.dart';

class SendPhoneVerificationCodeUseCase
    extends UseCase<bool, SendPhoneVerificationCodeParams> {
  final AuthRepository authRepository;

  SendPhoneVerificationCodeUseCase({
    required this.authRepository,
  });

  @override
  Future<Either<Failure, bool>> call(
      SendPhoneVerificationCodeParams params) async {
    return await authRepository.sendPhoneVerificationSms(
        params.firebaseToken, params.uid, params.phoneNumber);
  }
}

class SendPhoneVerificationCodeParams extends Equatable {
  final String firebaseToken;
  final String uid;
  final String phoneNumber;

  const SendPhoneVerificationCodeParams({
    required this.firebaseToken,
    required this.uid,
    required this.phoneNumber,
  });

  @override
  List<Object?> get props {
    return [
      firebaseToken,
      uid,
      phoneNumber,
    ];
  }
}
