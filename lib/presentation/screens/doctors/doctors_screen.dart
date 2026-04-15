import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/enums/view_status.dart';
import '../../cubits/doctors_cubit.dart';
import '../../routing/app_router.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/state_placeholder.dart';
import '../../widgets/sections/doctor_card.dart';
import '../../widgets/sections/section_header.dart';
import '../../widgets/sections/specialization_filter_chips.dart';

class DoctorsScreen extends StatefulWidget {
  const DoctorsScreen({super.key});

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    final state = context.read<DoctorsCubit>().state;
    _searchController = TextEditingController(text: state.query);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (state.status == ViewStatus.initial) {
        context.read<DoctorsCubit>().load();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DoctorsCubit, DoctorsState>(
      builder: (context, state) {
        final cubit = context.read<DoctorsCubit>();

        return RefreshIndicator(
          onRefresh: cubit.load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
            children: [
              const SectionHeader(
                title: 'Врачи клиники',
                subtitle:
                    'Найдите специалиста по направлению, опыту и удобному времени приема.',
              ),
              const SizedBox(height: 18),
              AppTextField(
                controller: _searchController,
                label: 'Поиск по имени врача',
                hint: 'Например, Мария Кузнецова',
                suffixIcon: const Icon(Icons.search_rounded),
              ),
              const SizedBox(height: 12),
              SpecializationFilterChips(
                items: state.specializations,
                selectedId: state.selectedSpecializationId,
                onSelected: cubit.setSpecialization,
              ),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: () => cubit.setQuery(_searchController.text),
                icon: const Icon(Icons.tune_rounded),
                label: const Text('Применить фильтры'),
              ),
              const SizedBox(height: 20),
              if (state.status == ViewStatus.loading)
                const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.status == ViewStatus.error)
                StatePlaceholder(
                  icon: Icons.error_outline_rounded,
                  title: 'Список врачей недоступен',
                  subtitle: state.message ?? 'Попробуйте снова немного позже.',
                  actionLabel: 'Повторить',
                  onAction: cubit.load,
                )
              else if (state.doctors.isEmpty)
                const StatePlaceholder(
                  icon: Icons.search_off_rounded,
                  title: 'Ничего не найдено',
                  subtitle: 'Измените фильтр или поисковый запрос.',
                )
              else
                ...state.doctors.map(
                  (doctor) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DoctorCard(
                      doctor: doctor,
                      onTap: () => context.push('/app/doctors/${doctor.id}'),
                      onBook: () => context.push(
                        '/app/appointments/book',
                        extra: BookingRouteArgs(doctorId: doctor.id),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
