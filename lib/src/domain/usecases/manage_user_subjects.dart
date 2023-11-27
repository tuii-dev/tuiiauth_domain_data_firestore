import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:tuii_entity_models/tuii_entity_models.dart';
import 'package:tuiiauth_domain_data_firestore/src/domain/repositories/auth_repository.dart';
import 'package:tuiicore/core/enums/tuii_role_type.dart';
import 'package:tuiicore/core/errors/failure.dart';
import 'package:tuiicore/core/usecases/usecase.dart';

class ManageUserSubjectsUseCase
    extends UseCase<List<SubjectModel>, ManageUserSubjectsParams> {
  final AuthRepository authRepository;

  ManageUserSubjectsUseCase({
    required this.authRepository,
  });

  @override
  Future<Either<Failure, List<SubjectModel>>> call(
      ManageUserSubjectsParams params) async {
    final subjectsEither = await authRepository.manageUserSubjects(
        params.userId, params.role, params.subjectTags);

    return subjectsEither.fold((failure) {
      return Left(failure);
    }, (subjects) {
      return Right(subjects);
    });
  }
}

class ManageUserSubjectsParams extends Equatable {
  final String userId;
  final TuiiRoleType role;
  final List<String> subjectTags;

  const ManageUserSubjectsParams({
    required this.userId,
    required this.role,
    required this.subjectTags,
  });

  @override
  List<Object?> get props {
    return [
      userId,
      role,
      subjectTags,
    ];
  }
}
