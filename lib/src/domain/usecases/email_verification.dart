import 'package:dartz/dartz.dart';
import 'package:tuiiauth_domain_data_firestore/src/domain/repositories/auth_repository.dart';
import 'package:tuiicore/core/errors/failure.dart';
import 'package:tuiicore/core/usecases/usecase.dart';

class EmailVerificationUseCase extends UseCase<bool, NoParams> {
  final AuthRepository authRepository;

  EmailVerificationUseCase({
    required this.authRepository,
  });

  @override
  Future<Either<Failure, bool>> call(NoParams params) async {
    return await authRepository.sendEmailVerificationEmail();
  }
}
