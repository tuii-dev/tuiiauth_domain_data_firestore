import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:tuiiauth_domain_data_firestore/files/domain/repositories/auth_repository.dart';
import 'package:tuiicore/core/errors/failure.dart';
import 'package:tuiicore/core/usecases/usecase.dart';

class IsEmailUniqueUseCase extends UseCase<bool, IsEmailUniqueParams> {
  final AuthRepository authRepository;

  IsEmailUniqueUseCase({
    required this.authRepository,
  });

  @override
  Future<Either<Failure, bool>> call(IsEmailUniqueParams params) async {
    return authRepository.isEmailUnique(params.email);
  }
}

class IsEmailUniqueParams extends Equatable {
  final String email;

  const IsEmailUniqueParams({
    required this.email,
  });

  @override
  List<Object?> get props {
    return [
      email,
    ];
  }
}
