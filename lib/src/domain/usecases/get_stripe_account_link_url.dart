import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:tuiiauth_domain_data_firestore/src/domain/repositories/auth_repository.dart';
import 'package:tuiicore/core/errors/failure.dart';
import 'package:tuiicore/core/usecases/usecase.dart';

class GetStripeAccountLinkUrlUseCase
    implements UseCase<String, GetStripeAccountLinkUrlParams> {
  final AuthRepository repository;

  GetStripeAccountLinkUrlUseCase({required this.repository});

  @override
  Future<Either<Failure, String>> call(
      GetStripeAccountLinkUrlParams params) async {
    return await repository.getStripeAccountLinkUrl(
      params.firebaseToken,
      params.createAccountUrl,
      params.tutorId,
      params.tutorEmail,
      params.tutorFirstName,
      params.tutorLastName,
      params.tutorUrl,
      params.tutorCountryCode,
      params.tutorCurrencyCode,
    );
  }
}

class GetStripeAccountLinkUrlParams extends Equatable {
  final String firebaseToken;
  final String createAccountUrl;
  final String tutorId;
  final String tutorEmail;
  final String tutorFirstName;
  final String tutorLastName;
  final String tutorUrl;
  final String tutorCountryCode;
  final String tutorCurrencyCode;

  const GetStripeAccountLinkUrlParams({
    required this.firebaseToken,
    required this.createAccountUrl,
    required this.tutorId,
    required this.tutorEmail,
    required this.tutorFirstName,
    required this.tutorLastName,
    required this.tutorUrl,
    required this.tutorCountryCode,
    required this.tutorCurrencyCode,
  });

  @override
  List<Object> get props => [
        firebaseToken,
        createAccountUrl,
        tutorId,
        tutorEmail,
        tutorFirstName,
        tutorLastName,
        tutorUrl,
        tutorCountryCode,
        tutorCurrencyCode,
      ];
}
