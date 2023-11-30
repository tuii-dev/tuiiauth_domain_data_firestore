import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:tuiiauth_domain_data_firestore/files/domain/repositories/auth_repository.dart';
import 'package:tuiicore/core/errors/failure.dart';
import 'package:tuiicore/core/usecases/usecase.dart';

class ForgotPasswordUseCase extends UseCase<bool, ForgotPasswordParams> {
  final AuthRepository authRepository;

  ForgotPasswordUseCase({
    required this.authRepository,
  });

  @override
  Future<Either<Failure, bool>> call(ForgotPasswordParams params) async {
    return await authRepository.sendPasswordResetEmail(email: params.email);

    // return sendEither.fold((failure) {
    //   return Left(failure);
    // }, (success) {
    //   return Right(success);
    // });
  }
}

class ForgotPasswordParams extends Equatable {
  final String email;
  const ForgotPasswordParams({
    required this.email,
  });

  @override
  List<Object?> get props {
    return [
      email,
    ];
  }
}
