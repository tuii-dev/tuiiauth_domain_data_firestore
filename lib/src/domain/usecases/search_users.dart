import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:tuii_entity_models/tuii_entity_models.dart';
import 'package:tuiiauth_domain_data_firestore/src/domain/repositories/auth_repository.dart';
import 'package:tuiicore/core/enums/tuii_role_type.dart';
import 'package:tuiicore/core/errors/failure.dart';
import 'package:tuiicore/core/usecases/usecase.dart';

class SearchUsersUseCase extends UseCase<List<UserModel>, SearchUsersParams> {
  final AuthRepository authRepository;

  SearchUsersUseCase({
    required this.authRepository,
  });

  @override
  Future<Either<Failure, List<UserModel>>> call(
      SearchUsersParams params) async {
    final searchEither =
        await authRepository.searchUsers(params.roleType, params.searchTerms);

    return searchEither.fold((failure) {
      return Left(failure);
    }, (users) {
      return Right(users);
    });
  }
}

class SearchUsersParams extends Equatable {
  final TuiiRoleType roleType;
  final List<String> searchTerms;

  const SearchUsersParams({
    required this.roleType,
    required this.searchTerms,
  });

  @override
  List<Object?> get props {
    return [
      roleType,
      searchTerms,
    ];
  }
}
