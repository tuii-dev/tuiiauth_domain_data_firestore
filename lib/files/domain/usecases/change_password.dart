import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:tuiiauth_domain_data_firestore/files/domain/repositories/auth_repository.dart';
import 'package:tuiicore/core/errors/failure.dart';
import 'package:tuiicore/core/usecases/usecase.dart';
import 'package:tuiientitymodels/files/auth/data/models/user_model.dart';

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
