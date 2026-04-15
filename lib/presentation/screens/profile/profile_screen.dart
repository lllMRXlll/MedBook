import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/enums/view_status.dart';
import '../../../core/utils/date_formatter.dart';
import '../../cubits/auth_cubit.dart';
import '../../cubits/profile_cubit.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/state_placeholder.dart';
import '../../widgets/sections/section_header.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<ProfileCubit>();
      if (cubit.state.status == ViewStatus.initial) {
        cubit.load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        if (state.status == ViewStatus.loading && state.user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == ViewStatus.error && state.user == null) {
          return StatePlaceholder(
            icon: Icons.person_off_outlined,
            title: 'Профиль временно недоступен',
            subtitle: state.message ?? 'Попробуйте обновить данные позже.',
            actionLabel: 'Повторить',
            onAction: () => context.read<ProfileCubit>().load(),
          );
        }

        final user = state.user ?? context.read<AuthCubit>().state.user;
        if (user == null) {
          return const SizedBox.shrink();
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
          children: [
            const SectionHeader(
              title: 'Профиль пациента',
              subtitle:
                  'Проверьте контактные данные и обновите их при необходимости.',
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      child: Text(user.fullName.characters.first),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.fullName,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(user.email),
                    const SizedBox(height: 4),
                    Text(user.phone),
                    if (user.city != null) ...[
                      const SizedBox(height: 4),
                      Text(user.city!),
                    ],
                    if (user.birthDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Дата рождения: ${DateFormatter.fullDate(user.birthDate!)}',
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Редактировать профиль',
              icon: Icons.edit_outlined,
              onPressed: () => context.push('/app/profile/edit'),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Выйти из аккаунта',
              secondary: true,
              onPressed: () => context.read<AuthCubit>().logout(),
            ),
          ],
        );
      },
    );
  }
}
