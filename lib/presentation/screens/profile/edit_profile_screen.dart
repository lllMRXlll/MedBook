import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/enums/view_status.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../domain/requests/update_profile_request.dart';
import '../../cubits/auth_cubit.dart';
import '../../cubits/profile_cubit.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/primary_button.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _birthDateController = TextEditingController();
  DateTime? _birthDate;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }

    final user =
        context.read<ProfileCubit>().state.user ??
        context.read<AuthCubit>().state.user;
    if (user != null) {
      _nameController.text = user.fullName;
      _emailController.text = user.email;
      _phoneController.text = user.phone;
      _cityController.text = user.city ?? '';
      _birthDate = user.birthDate;
      _birthDateController.text = _birthDate == null
          ? ''
          : DateFormatter.fullDate(_birthDate!);
    }
    _initialized = true;
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('ru', 'RU'),
      initialDate: _birthDate ?? DateTime(now.year - 25),
      firstDate: DateTime(1940),
      lastDate: now,
    );

    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _birthDateController.text = DateFormatter.fullDate(picked);
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    context.read<ProfileCubit>().updateProfile(
      UpdateProfileRequest(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        city: _cityController.text.trim(),
        birthDate: _birthDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Редактирование профиля')),
      body: BlocConsumer<ProfileCubit, ProfileState>(
        listenWhen: (previous, current) =>
            previous.submissionStatus != current.submissionStatus ||
            previous.message != current.message,
        listener: (context, state) {
          if (state.submissionStatus == ViewStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message ?? 'Профиль обновлен')),
            );
            Navigator.of(context).pop();
          } else if (state.submissionStatus == ViewStatus.error &&
              state.message != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message!)));
          }
        },
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    AppTextField(
                      controller: _nameController,
                      label: 'ФИО',
                      validator: (value) {
                        if (value == null || value.trim().length < 3) {
                          return 'Введите полное имя';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _emailController,
                      label: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null ||
                            !RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
                          return 'Введите корректный email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _phoneController,
                      label: 'Телефон',
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().length < 10) {
                          return 'Введите корректный телефон';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AppTextField(controller: _cityController, label: 'Город'),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _birthDateController,
                      label: 'Дата рождения',
                      readOnly: true,
                      onTap: _pickBirthDate,
                      suffixIcon: const Icon(Icons.calendar_today_rounded),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      label: 'Сохранить изменения',
                      onPressed: _submit,
                      isLoading:
                          state.submissionStatus == ViewStatus.submitting,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
