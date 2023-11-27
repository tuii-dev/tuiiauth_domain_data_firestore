import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:tuiiauth_domain_data_firestore/src/domain/repositories/auth_repository.dart';
import 'package:tuiicore/core/errors/failure.dart';
import 'package:tuiicore/core/usecases/usecase.dart';

class ValidateSignUpHashUseCase
    extends UseCase<bool, ValidateSignUpHashParams> {
  final AuthRepository authRepository;

  ValidateSignUpHashUseCase({
    required this.authRepository,
  });

  @override
  Future<Either<Failure, bool>> call(ValidateSignUpHashParams params) async {
    return await authRepository.validateSignUpHash(
        validationUrl: params.validationUrl, hash: params.hash);
  }
}

class ValidateSignUpHashParams extends Equatable {
  final String validationUrl;
  final String hash;

  const ValidateSignUpHashParams({
    required this.validationUrl,
    required this.hash,
  });

  @override
  List<Object?> get props {
    return [
      validationUrl,
      hash,
    ];
  }
}
