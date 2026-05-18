import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/common_widgets/cyber_button.dart';
import '../../../../core/common_widgets/cyber_text_field.dart';
import '../../../../core/common_widgets/glass_container.dart';
import '../../../../core/utils/validation_utils.dart';
import '../providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _avatarUrlController = TextEditingController();
  final _nationalityController = TextEditingController();

  String _selectedGender = 'Unknown';
  DateTime? _dateOfBirth;
  File? _avatarFile;

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _avatarUrlController.dispose();
    _nationalityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70);

    if (pickedFile != null) {
      setState(() {
        _avatarFile = File(pickedFile.path);
        _avatarUrlController.clear(); // Clear URL if local file is selected
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.neonPurple,
              onPrimary: Colors.white,
              surface: AppTheme.darkBackground,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _dateOfBirth) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }

  void _handleSignup() {
    if (_formKey.currentState!.validate()) {
      if (_dateOfBirth == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select Date of Birth'),
            backgroundColor: AppTheme.electricPink,
          ),
        );
        return;
      }

      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passwords do not match'),
            backgroundColor: AppTheme.electricPink,
          ),
        );
        return;
      }

      ref
          .read(authControllerProvider.notifier)
          .signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _fullNameController.text.trim(),
            username: _usernameController.text.trim(),
            gender: _selectedGender,
            dateOfBirth: _dateOfBirth!,
            nationality: _nationalityController.text.trim(),
            avatarFile: _avatarFile,
            avatarUrl: _avatarUrlController.text.isNotEmpty
                ? _avatarUrlController.text.trim()
                : null,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString()),
              backgroundColor: AppTheme.electricPink,
            ),
          );
        },
      );
    });

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.cyanBlue),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'NEW IDENTITY',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                GlassContainer(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Avatar Selection
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: AppTheme.darkBackground,
                            builder: (context) => SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(
                                      Icons.camera_alt,
                                      color: AppTheme.cyanBlue,
                                    ),
                                    title: const Text(
                                      'Take Photo',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _pickImage(ImageSource.camera);
                                    },
                                  ),
                                  ListTile(
                                    leading: const Icon(
                                      Icons.photo_library,
                                      color: AppTheme.neonPurple,
                                    ),
                                    title: const Text(
                                      'Choose from Gallery',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      _pickImage(ImageSource.gallery);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: AppTheme.glassBorder,
                          backgroundImage: _avatarFile != null
                              ? FileImage(_avatarFile!)
                              : (_avatarUrlController.text.isNotEmpty
                                        ? NetworkImage(
                                            _avatarUrlController.text,
                                          )
                                        : null)
                                    as ImageProvider?,
                          child:
                              _avatarFile == null &&
                                  _avatarUrlController.text.isEmpty
                              ? const Icon(
                                  Icons.person_add,
                                  size: 40,
                                  color: AppTheme.cyanBlue,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(height: 16),
                      CyberTextField(
                        controller: _avatarUrlController,
                        labelText: 'AVATAR URL (OPTIONAL)',
                        prefixIcon: Icons.link,
                        onChanged: (val) =>
                            setState(() {}), // Update avatar preview
                      ),
                      const SizedBox(height: 16),
                      CyberTextField(
                        controller: _fullNameController,
                        labelText: 'FULL NAME',
                        prefixIcon: Icons.badge_outlined,
                        validator: (val) => val!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      CyberTextField(
                        controller: _usernameController,
                        labelText: 'GAMER TAG',
                        prefixIcon: Icons.sports_esports_outlined,
                        onChanged: (val) => setState(() {}),
                        validator: ValidationUtils.validateUsername,
                      ),
                      const SizedBox(height: 16),

                      // Gender Dropdown inside styling
                      DropdownButtonFormField<String>(
                        initialValue: _selectedGender,
                        dropdownColor: AppTheme.darkBackground,
                        decoration: InputDecoration(
                          labelText: 'GENDER',
                          labelStyle: const TextStyle(color: Colors.white60),
                          prefixIcon: const Icon(
                            Icons.people_outline,
                            color: AppTheme.cyanBlue,
                          ),
                          filled: true,
                          fillColor: AppTheme.glassBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppTheme.glassBorder,
                            ),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        items: ['Male', 'Female', 'Non-binary', 'Unknown'].map((
                          String value,
                        ) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedGender = val!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Date of Birth
                      InkWell(
                        onTap: _selectDate,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'DATE OF BIRTH',
                            labelStyle: const TextStyle(color: Colors.white60),
                            prefixIcon: const Icon(
                              Icons.calendar_today,
                              color: AppTheme.cyanBlue,
                            ),
                            filled: true,
                            fillColor: AppTheme.glassBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppTheme.glassBorder,
                              ),
                            ),
                          ),
                          child: Text(
                            _dateOfBirth == null
                                ? 'SELECT DATE'
                                : '${_dateOfBirth!.year}-${_dateOfBirth!.month.toString().padLeft(2, '0')}-${_dateOfBirth!.day.toString().padLeft(2, '0')}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      CyberTextField(
                        controller: _nationalityController,
                        labelText: 'NATIONALITY',
                        prefixIcon: Icons.flag_outlined,
                        validator: (val) => val!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      CyberTextField(
                        controller: _emailController,
                        labelText: 'EMAIL ADDRESS',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (val) => setState(() {}),
                        validator: ValidationUtils.validateEmail,
                      ),
                      const SizedBox(height: 16),
                      CyberTextField(
                        controller: _passwordController,
                        labelText: 'PASSWORD',
                        prefixIcon: Icons.vpn_key_outlined,
                        obscureText: true,
                        onChanged: (val) => setState(() {}),
                        validator: ValidationUtils.validatePassword,
                      ),
                      const SizedBox(height: 8),

                      // Dynamic Password Strength Meter
                      Builder(
                        builder: (context) {
                          final pass = _passwordController.text;
                          final score = ValidationUtils.getPasswordStrengthScore(pass);
                          final strengthText = ValidationUtils.getPasswordStrengthText(pass);
                          final checks = ValidationUtils.evaluatePasswordStrength(pass);

                          Color strengthColor = AppTheme.electricPink;
                          if (score > 0.4 && score <= 0.8) {
                            strengthColor = Colors.amber;
                          } else if (score > 0.8) {
                            strengthColor = AppTheme.cyanBlue;
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'SECURITY LEVEL: $strengthText',
                                    style: TextStyle(
                                      color: strengthColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  Text(
                                    '${(score * 100).toInt()}%',
                                    style: TextStyle(
                                      color: strengthColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: score,
                                  minHeight: 6,
                                  backgroundColor: Colors.white10,
                                  color: strengthColor,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Checklist Grid
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.02),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.05),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    _buildChecklistRow('8+ Characters', checks['isMinLength']!),
                                    const SizedBox(height: 4),
                                    _buildChecklistRow('Uppercase Letter [A-Z]', checks['hasUppercase']!),
                                    const SizedBox(height: 4),
                                    _buildChecklistRow('Lowercase Letter [a-z]', checks['hasLowercase']!),
                                    const SizedBox(height: 4),
                                    _buildChecklistRow('Numeric Digit [0-9]', checks['hasDigits']!),
                                    const SizedBox(height: 4),
                                    _buildChecklistRow('Special Character [@, #, etc.]', checks['hasSpecial']!),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }
                      ),
                      const SizedBox(height: 16),
                      CyberTextField(
                        controller: _confirmPasswordController,
                        labelText: 'CONFIRM PASSWORD',
                        prefixIcon: Icons.vpn_key,
                        obscureText: true,
                        validator: (val) {
                          if (val != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: CyberButton(
                          text: 'CREATE IDENTITY',
                          icon: Icons.person_add,
                          isLoading: authState.isLoading,
                          onPressed: _handleSignup,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistRow(String text, bool isValid) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle_outline : Icons.cancel_outlined,
          color: isValid ? AppTheme.cyanBlue : AppTheme.electricPink,
          size: 14,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: isValid ? Colors.white : Colors.white30,
            fontSize: 11,
            fontWeight: isValid ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
