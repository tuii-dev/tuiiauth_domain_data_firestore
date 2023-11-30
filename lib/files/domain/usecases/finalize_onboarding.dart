import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:tuiiauth_domain_data_firestore/files/domain/repositories/auth_repository.dart';
import 'package:tuiicore/core/errors/failure.dart';
import 'package:tuiicore/core/usecases/usecase.dart';
import 'package:tuiientitymodels/files/auth/domain/entities/user.dart';

class FinalizeOnboardingUseCase
    extends UseCase<bool, FinalizeOnboardingParams> {
  final AuthRepository authRepository;

  FinalizeOnboardingUseCase({
    required this.authRepository,
  });

  @override
  Future<Either<Failure, bool>> call(FinalizeOnboardingParams params) async {
    final finalizeEither = await authRepository.finalizeOnboarding(
        params.user.toModel(), params.newEmail);

    return finalizeEither.fold((failure) {
      return Left(failure);
    }, (success) {
      return Right(success);
    });
  }
}

class FinalizeOnboardingParams extends Equatable {
  final User user;
  final String? newEmail;
  const FinalizeOnboardingParams({
    required this.user,
    this.newEmail,
  });

  @override
  List<Object?> get props {
    return [
      user,
      newEmail,
    ];
  }
}
