import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/enums/view_status.dart';
import '../../cubits/auth_cubit.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/fade_slide_in.dart';
import '../../widgets/common/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    context.read<AuthCubit>().register(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocListener<AuthCubit, AuthState>(
          listenWhen: (previous, current) =>
              previous.message != current.message && current.message != null,
          listener: (context, state) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message!)));
            context.read<AuthCubit>().clearMessage();
          },
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: FadeSlideIn(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Создайте аккаунт пациента',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'После регистрации вы сразу попадете в личный кабинет и сможете выбрать врача.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 24),
                            AppTextField(
                              controller: _nameController,
                              label: 'ФИО',
                              textInputAction: TextInputAction.next,
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
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value == null ||
                                    !RegExp(
                                      r'^[^@]+@[^@]+\.[^@]+$',
                                    ).hasMatch(value)) {
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
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value == null || value.trim().length < 10) {
                                  return 'Введите корректный номер телефона';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _passwordController,
                              label: 'Пароль',
                              obscureText: _obscurePassword,
                              validator: (value) {
                                if (value == null || value.length < 6) {
                                  return 'Минимум 6 символов';
                                }
                                return null;
                              },
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            BlocBuilder<AuthCubit, AuthState>(
                              builder: (context, state) {
                                return PrimaryButton(
                                  label: 'Зарегистрироваться',
                                  onPressed: _submit,
                                  isLoading:
                                      state.status == ViewStatus.submitting,
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            PrimaryButton(
                              label: 'У меня уже есть аккаунт',
                              onPressed: () => context.go('/login'),
                              secondary: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
