import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:tuiiauth_domain_data_firestore/files/domain/repositories/auth_repository.dart';
import 'package:tuiicore/core/enums/channel_type.dart';
import 'package:tuiicore/core/errors/failure.dart';
import 'package:tuiicore/core/usecases/usecase.dart';
import 'package:tuiientitymodels/files/auth/data/models/invitation_model.dart';

class SendDirectConnectInvitationsUseCase
    extends UseCase<List<InvitationModel>, SendDirectConnectInvitationsParams> {
  final AuthRepository repository;

  SendDirectConnectInvitationsUseCase({
    required this.repository,
  });

  @override
  Future<Either<Failure, List<InvitationModel>>> call(
      SendDirectConnectInvitationsParams params) async {
    return await repository.sendDirectConnectInvitations(
        params.invitations,
        params.createAppLinkUrl,
        params.channel,
        params.tutorId,
        params.tutorFirstName,
        params.tutorLastName);
  }
}

class SendDirectConnectInvitationsParams extends Equatable {
  final List<InvitationModel> invitations;
  final String createAppLinkUrl;
  final ChannelType channel;
  final String tutorId;
  final String tutorFirstName;
  final String tutorLastName;

  const SendDirectConnectInvitationsParams({
    required this.invitations,
    required this.createAppLinkUrl,
    required this.channel,
    required this.tutorId,
    required this.tutorFirstName,
    required this.tutorLastName,
  });

  @override
  List<Object?> get props {
    return [
      invitations,
      createAppLinkUrl,
      tutorId,
      tutorFirstName,
      tutorLastName,
    ];
  }
}
