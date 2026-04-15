class UpdateProfileRequest {
  const UpdateProfileRequest({
    required this.fullName,
    required this.email,
    required this.phone,
    this.birthDate,
    this.city,
  });

  final String fullName;
  final String email;
  final String phone;
  final DateTime? birthDate;
  final String? city;
}
