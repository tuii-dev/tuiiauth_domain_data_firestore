import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:tuiiauth_domain_data_firestore/files/domain/repositories/auth_repository.dart';
import 'package:tuiicore/core/errors/failure.dart';
import 'package:tuiicore/core/usecases/usecase.dart';

class RevokeZoomTokenUseCase extends UseCase<bool, RevokeZoomTokenParams> {
  final AuthRepository authRepository;

  RevokeZoomTokenUseCase({
    required this.authRepository,
  });

  @override
  Future<Either<Failure, bool>> call(RevokeZoomTokenParams params) async {
    return await authRepository.revokeZoomToken(params.zoomTokenUrl,
        params.tutorId, params.firebaseToken, params.token);

    // return domainEither.fold((failure) {
    //   return Left(failure);
    // }, (success) {
    //   return Right(success);
    // });
  }
}

class RevokeZoomTokenParams extends Equatable {
  final String zoomTokenUrl;
  final String tutorId;
  final String firebaseToken;
  final String token;
  const RevokeZoomTokenParams({
    required this.zoomTokenUrl,
    required this.tutorId,
    required this.firebaseToken,
    required this.token,
  });

  @override
  List<Object?> get props {
    return [
      zoomTokenUrl,
      tutorId,
      firebaseToken,
      token,
    ];
  }
}
