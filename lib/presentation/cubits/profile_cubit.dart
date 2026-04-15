import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/enums/view_status.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/requests/update_profile_request.dart';
import 'auth_cubit.dart';

class ProfileState extends Equatable {
  const ProfileState({
    required this.status,
    required this.submissionStatus,
    this.user,
    this.message,
  });

  const ProfileState.initial()
    : this(status: ViewStatus.initial, submissionStatus: ViewStatus.initial);

  final ViewStatus status;
  final ViewStatus submissionStatus;
  final User? user;
  final String? message;

  ProfileState copyWith({
    ViewStatus? status,
    ViewStatus? submissionStatus,
    User? user,
    String? message,
    bool clearMessage = false,
  }) {
    return ProfileState(
      status: status ?? this.status,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      user: user ?? this.user,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, submissionStatus, user, message];
}

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({
    required ProfileRepository profileRepository,
    required AuthCubit authCubit,
  }) : _profileRepository = profileRepository,
       _authCubit = authCubit,
       super(const ProfileState.initial());

  final ProfileRepository _profileRepository;
  final AuthCubit _authCubit;

  Future<void> load() async {
    emit(state.copyWith(status: ViewStatus.loading, clearMessage: true));
    try {
      final user = await _profileRepository.getProfile();
      emit(
        state.copyWith(
          status: ViewStatus.success,
          user: user,
          clearMessage: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ViewStatus.error,
          message: 'Не удалось загрузить профиль.',
        ),
      );
    }
  }

  Future<void> updateProfile(UpdateProfileRequest request) async {
    emit(
      state.copyWith(
        submissionStatus: ViewStatus.submitting,
        clearMessage: true,
      ),
    );
    try {
      final user = await _profileRepository.updateProfile(request);
      _authCubit.updateUser(user);
      emit(
        state.copyWith(
          status: ViewStatus.success,
          submissionStatus: ViewStatus.success,
          user: user,
          message: 'Профиль обновлен',
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          submissionStatus: ViewStatus.error,
          message: 'Не удалось сохранить изменения.',
        ),
      );
    }
  }

  void clearMessage() {
    emit(state.copyWith(clearMessage: true));
  }

  void reset() => emit(const ProfileState.initial());
}
