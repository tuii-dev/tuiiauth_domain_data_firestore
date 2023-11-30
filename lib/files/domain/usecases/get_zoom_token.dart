import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:tuiiauth_domain_data_firestore/files/domain/repositories/auth_repository.dart';
import 'package:tuiicore/core/errors/failure.dart';
import 'package:tuiicore/core/usecases/usecase.dart';
import 'package:tuiientitymodels/files/auth/data/models/create_zoom_token_response.dart';

class GetZoomTokenUseCase
    extends UseCase<CreateZoomTokenResponse, GetZoomTokenParams> {
  final AuthRepository authRepository;

  GetZoomTokenUseCase({
    required this.authRepository,
  });

  @override
  Future<Either<Failure, CreateZoomTokenResponse>> call(
      GetZoomTokenParams params) async {
    return await authRepository.getZoomToken(
        params.zoomTokenUrl, params.tutorId, params.firebaseToken, params.code);
  }
}

class GetZoomTokenParams extends Equatable {
  final String zoomTokenUrl;
  final String tutorId;
  final String firebaseToken;
  final String code;
  const GetZoomTokenParams({
    required this.zoomTokenUrl,
    required this.tutorId,
    required this.firebaseToken,
    required this.code,
  });

  @override
  List<Object?> get props {
    return [
      zoomTokenUrl,
      tutorId,
      firebaseToken,
      code,
    ];
  }
}
