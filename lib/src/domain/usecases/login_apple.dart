// import 'package:dartz/dartz.dart';
// import 'package:equatable/equatable.dart';
// import 'package:tuiicore/core/errors/failure.dart';
// import 'package:tuiicore/core/usecases/usecase.dart';
// import 'package:tuiiweb/features/auth/domain/entities/user.dart';
// import 'package:tuiiweb/features/auth/domain/repositories/auth_repository.dart';

// class LoginWithAppleUseCase extends UseCase<User, LoginWithAppleParams> {
//   final AuthRepository authRepository;

//   LoginWithAppleUseCase({
//     required this.authRepository,
//   });

//   @override
//   Future<Either<Failure, User>> call(LoginWithAppleParams params) async {
//     final loginEither = await authRepository.signInWithApple();

//     return loginEither.fold((failure) {
//       return Left(failure);
//     }, (model) {
//       return Right(User.fromModel(model: model));
//     });
//   }
// }

// class LoginWithAppleParams extends Equatable {
//   const LoginWithAppleParams();

//   @override
//   List<Object?> get props {
//     return [];
//   }
// }
