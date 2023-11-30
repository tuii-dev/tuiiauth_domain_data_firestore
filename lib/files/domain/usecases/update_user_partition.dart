import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:tuiiauth_domain_data_firestore/files/domain/repositories/auth_repository.dart';
import 'package:tuiicore/core/errors/failure.dart';
import 'package:tuiicore/core/usecases/usecase.dart';

class UpdateUserPartitionUseCase
    extends UseCase<bool, UpdateUserPartitionParams> {
  final AuthRepository authRepository;

  UpdateUserPartitionUseCase({
    required this.authRepository,
  });

  @override
  Future<Either<Failure, bool>> call(UpdateUserPartitionParams params) async {
    final updateEither = await authRepository.updateUserPartition(
        params.userId, params.partition);

    return updateEither.fold((failure) {
      return Left(failure);
    }, (success) {
      return Right(success);
    });
  }
}

class UpdateUserPartitionParams extends Equatable {
  final String userId;
  final Map<String, dynamic> partition;

  const UpdateUserPartitionParams({
    required this.userId,
    required this.partition,
  });

  @override
  List<Object?> get props {
    return [
      userId,
      partition,
    ];
  }
}
