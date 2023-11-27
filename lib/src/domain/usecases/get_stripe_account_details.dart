import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:tuii_entity_models/tuii_entity_models.dart';
import 'package:tuiiauth_domain_data_firestore/src/domain/repositories/auth_repository.dart';
import 'package:tuiicore/core/errors/failure.dart';
import 'package:tuiicore/core/usecases/usecase.dart';

class GetStripeAccountDetailsUseCase
    implements
        UseCase<StripeAccountDetailsModel, GetStripeAccountDetailsParams> {
  final AuthRepository repository;

  GetStripeAccountDetailsUseCase({required this.repository});

  @override
  Future<Either<Failure, StripeAccountDetailsModel>> call(
      GetStripeAccountDetailsParams params) async {
    return await repository.getStripeAccountDetails(params.firebaseToken,
        params.getAccountDetailsUrl, params.stripeAccountId);
  }
}

class GetStripeAccountDetailsParams extends Equatable {
  final String firebaseToken;
  final String getAccountDetailsUrl;
  final String stripeAccountId;

  const GetStripeAccountDetailsParams({
    required this.firebaseToken,
    required this.getAccountDetailsUrl,
    required this.stripeAccountId,
  });

  @override
  List<Object> get props =>
      [firebaseToken, getAccountDetailsUrl, stripeAccountId];
}
