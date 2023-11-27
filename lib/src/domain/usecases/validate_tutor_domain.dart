import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:tuiiauth_domain_data_firestore/src/domain/repositories/auth_repository.dart';
import 'package:tuiicore/core/errors/failure.dart';
import 'package:tuiicore/core/usecases/usecase.dart';

class ValidateTutorDomainUseCase
    extends UseCase<bool, ValidateTutorDomainParams> {
  final AuthRepository authRepository;

  ValidateTutorDomainUseCase({
    required this.authRepository,
  });

  @override
  Future<Either<Failure, bool>> call(ValidateTutorDomainParams params) async {
    return await authRepository.isDomainUnique(params.tutorId, params.domain);

    // return domainEither.fold((failure) {
    //   return Left(failure);
    // }, (success) {
    //   return Right(success);
    // });
  }
}

class ValidateTutorDomainParams extends Equatable {
  final String tutorId;
  final String domain;
  const ValidateTutorDomainParams({
    required this.tutorId,
    required this.domain,
  });

  @override
  List<Object?> get props {
    return [
      tutorId,
      domain,
    ];
  }
}
