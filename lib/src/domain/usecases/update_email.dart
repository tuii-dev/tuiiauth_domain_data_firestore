import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:tuiiauth_domain_data_firestore/src/domain/repositories/auth_repository.dart';
import 'package:tuiicore/core/errors/failure.dart';
import 'package:tuiicore/core/usecases/usecase.dart';

class UpdateEmailUseCase extends UseCase<bool, UpdateEmailParams> {
  final AuthRepository authRepository;

  UpdateEmailUseCase({
    required this.authRepository,
  });

  @override
  Future<Either<Failure, bool>> call(UpdateEmailParams params) async {
    final updateEither = await authRepository.updateEmail(params.newEmail);

    return updateEither.fold((failure) {
      return Left(failure);
    }, (success) {
      return Right(success);
    });
  }
}

class UpdateEmailParams extends Equatable {
  final String newEmail;
  const UpdateEmailParams({
    required this.newEmail,
  });

  @override
  List<Object?> get props {
    return [
      newEmail,
    ];
  }
}
