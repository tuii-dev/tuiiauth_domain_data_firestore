import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:tuiiauth_domain_data_firestore/files/domain/repositories/auth_repository.dart';
import 'package:tuiicore/core/errors/failure.dart';
import 'package:tuiicore/core/usecases/usecase.dart';
import 'package:tuiientitymodels/files/auth/data/models/zoom_account_details_model.dart';

class GetZoomAccountDetailsUseCase
    extends UseCase<ZoomAccountDetailsModel, GetZoomAccountDetailsParams> {
  final AuthRepository authRepository;

  GetZoomAccountDetailsUseCase({
    required this.authRepository,
  });

  @override
  Future<Either<Failure, ZoomAccountDetailsModel>> call(
      GetZoomAccountDetailsParams params) async {
    return await authRepository.getZoomAccountDetails(params.zoomAccountUrl,
        params.tutorId, params.firebaseToken, params.token);
  }
}

class GetZoomAccountDetailsParams extends Equatable {
  final String zoomAccountUrl;
  final String tutorId;
  final String firebaseToken;
  final String token;

  const GetZoomAccountDetailsParams({
    required this.zoomAccountUrl,
    required this.tutorId,
    required this.firebaseToken,
    required this.token,
  });

  @override
  List<Object?> get props {
    return [
      zoomAccountUrl,
      tutorId,
      firebaseToken,
      token,
    ];
  }
}
