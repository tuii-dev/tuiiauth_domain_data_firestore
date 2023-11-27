import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:tuii_entity_models/tuii_entity_models.dart';
import 'package:tuiiauth_domain_data_firestore/src/domain/repositories/auth_repository.dart';
import 'package:tuiicore/core/errors/failure.dart';
import 'package:tuiicore/core/usecases/usecase.dart';

class ChangePasswordUseCase extends UseCase<UserModel, ChangePasswordParams> {
  final AuthRepository authRepository;

  ChangePasswordUseCase({
    required this.authRepository,
  });

  @override
  Future<Either<Failure, UserModel>> call(ChangePasswordParams params) async {
    return await authRepository.changePassword(
        currentPassword: params.currentPassword,
        newPassword: params.newPassword);
  }
}

class ChangePasswordParams extends Equatable {
  final String currentPassword;
  final String newPassword;

  const ChangePasswordParams({
    required this.currentPassword,
    required this.newPassword,
  });

  @override
  List<Object?> get props {
    return [
      currentPassword,
      newPassword,
    ];
  }
}
