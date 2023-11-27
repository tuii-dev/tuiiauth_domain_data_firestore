import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:tuii_entity_models/tuii_entity_models.dart';
import 'package:tuiiauth_domain_data_firestore/src/domain/repositories/auth_repository.dart';
import 'package:tuiicore/core/errors/failure.dart';
import 'package:tuiicore/core/usecases/usecase.dart';

class UpdateUserUseCase extends UseCase<bool, UpdateUserParams> {
  final AuthRepository authRepository;

  UpdateUserUseCase({
    required this.authRepository,
  });

  @override
  Future<Either<Failure, bool>> call(UpdateUserParams params) async {
    final updateEither =
        await authRepository.updateUser(params.user.toModel(), params.newEmail);

    if (params.childIsNew == true) {
      final finalizeChildEither = await authRepository
          .finalizeOnboardingForNewChild(params.user.toModel());

      finalizeChildEither.fold((failure) {
        debugPrint('New child finalization failed: ${failure.message}');
      }, (success) {
        debugPrint('New child finalization succeeded');
      });
    }

    return updateEither.fold((failure) {
      return Left(failure);
    }, (success) {
      return Right(success);
    });
  }
}

class UpdateUserParams extends Equatable {
  final User user;
  final String? newEmail;
  final bool? childIsNew;
  final bool? healZoom400Errors;

  const UpdateUserParams({
    required this.user,
    this.newEmail,
    this.childIsNew = false,
    this.healZoom400Errors = false,
  });

  @override
  List<Object?> get props {
    return [
      user,
      newEmail,
      childIsNew,
      healZoom400Errors,
    ];
  }
}
