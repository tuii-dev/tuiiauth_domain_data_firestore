import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:tuiiauth_domain_data_firestore/files/domain/repositories/auth_repository.dart';
import 'package:tuiicore/core/errors/failure.dart';
import 'package:tuiicore/core/usecases/usecase.dart';
import 'package:tuiientitymodels/files/auth/data/models/stripe_account_details_model.dart';

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
