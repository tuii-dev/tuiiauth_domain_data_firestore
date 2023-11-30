import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:tuiiauth_domain_data_firestore/files/domain/repositories/auth_repository.dart';
import 'package:tuiicore/core/errors/failure.dart';
import 'package:tuiicore/core/usecases/usecase.dart';
import 'package:tuiientitymodels/files/auth/domain/entities/user.dart';

class LoginWithEmailAndPasswordUseCase
    extends UseCase<User, LoginWithEmailAndPasswordParams> {
  final AuthRepository authRepository;

  LoginWithEmailAndPasswordUseCase({
    required this.authRepository,
  });

  @override
  Future<Either<Failure, User>> call(
      LoginWithEmailAndPasswordParams params) async {
    return (params.isSignUp) ? _runCreate(params) : _runLogin(params);
  }

  Future<Either<Failure, User>> _runCreate(
      LoginWithEmailAndPasswordParams params) async {
    final loginEither = await authRepository.createUserWithEmailAndPassword(
      email: params.email,
      password: params.password,
    );

    return loginEither.fold((failure) {
      return Left(failure);
    }, (model) {
      return Right(User.fromModel(model: model));
    });
  }

  Future<Either<Failure, User>> _runLogin(
      LoginWithEmailAndPasswordParams params) async {
    final loginEither = await authRepository.loginWithEmailAndPassword(
        email: params.email, password: params.password);

    return loginEither.fold((failure) {
      return Left(failure);
    }, (model) {
      return Right(User.fromModel(model: model));
    });
  }
}

class LoginWithEmailAndPasswordParams extends Equatable {
  final String email;
  final String password;
  final bool isSignUp;

  const LoginWithEmailAndPasswordParams({
    required this.email,
    required this.password,
    this.isSignUp = false,
  });

  @override
  List<Object?> get props {
    return [
      email,
      password,
      isSignUp,
    ];
  }
}
