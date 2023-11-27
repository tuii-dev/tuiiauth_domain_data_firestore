import 'package:dartz/dartz.dart';
import 'package:tuiiauth_domain_data_firestore/src/domain/repositories/auth_repository.dart';
import 'package:tuiicore/core/errors/failure.dart';
import 'package:tuiicore/core/usecases/usecase.dart';

class RefreshFirebaseUserUseCase extends UseCase<bool, NoParams> {
  final AuthRepository authRepository;

  RefreshFirebaseUserUseCase({
    required this.authRepository,
  });

  @override
  Future<Either<Failure, bool>> call(NoParams params) async {
    return await authRepository.refreshFirebaseUser();
  }
}

// class EmailVerificationParams extends Equatable {
//   final UserModel user;
//   const EmailVerificationParams({
//     required this.user,
//   });

//   @override
//   List<Object?> get props {
//     return [
//       user,
//     ];
//   }
// }
