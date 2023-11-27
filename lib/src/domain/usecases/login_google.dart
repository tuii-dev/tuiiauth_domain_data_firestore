import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:tuii_entity_models/tuii_entity_models.dart';
import 'package:tuiiauth_domain_data_firestore/src/domain/repositories/auth_repository.dart';
import 'package:tuiicore/core/errors/failure.dart';
import 'package:tuiicore/core/usecases/usecase.dart';

class LoginWithGoogleUseCase extends UseCase<User, SignInWithGoogleParams> {
  final AuthRepository authRepository;

  LoginWithGoogleUseCase({
    required this.authRepository,
  });

  @override
  Future<Either<Failure, User>> call(SignInWithGoogleParams params) async {
    final loginEither = await authRepository.signInWithGoogle();

    return loginEither.fold((failure) {
      if (failure.code! == 'popup_closed_by_user') {
        failure = failure.copyWith(supressMessaging: true);
      }
      return Left(failure);
    }, (model) {
      return Right(User.fromModel(model: model));
    });
  }
}

class SignInWithGoogleParams extends Equatable {
  const SignInWithGoogleParams();

  @override
  List<Object?> get props {
    return [];
  }
}
