import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:tuiiauth_domain_data_firestore/tuiiauth_domain_data_firestore.dart';
import 'package:tuiicore/core/errors/failure.dart';
import 'package:tuiicore/core/usecases/usecase.dart';

class LogoutUseCase extends UseCase<bool, LogoutParams> {
  final AuthRepository authRepository;

  LogoutUseCase({
    required this.authRepository,
  });

  @override
  Future<Either<Failure, bool>> call(LogoutParams params) async {
    return authRepository.logout();
  }
}

class LogoutParams extends Equatable {
  const LogoutParams();

  @override
  List<Object?> get props {
    return [];
  }
}
