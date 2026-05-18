import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _supabase;

  AuthRepositoryImpl(this._supabase);

  @override
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  @override
  User? get currentUser => _supabase.auth.currentUser;

  @override
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String username,
    required String gender,
    required DateTime dateOfBirth,
    required String nationality,
    File? avatarFile,
    String? avatarUrl,
  }) async {
    try {
      // 1. Sign up user in auth.users
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = authResponse.user;
      if (user == null) {
        throw Exception('Signup failed: No user returned.');
      }

      String finalAvatarUrl = avatarUrl ?? '';

      // 2. Upload avatar if file is provided
      if (avatarFile != null) {
        final fileExt = avatarFile.path.split('.').last;
        final fileName = '${user.id}_avatar.$fileExt';

        await _supabase.storage
            .from('avatars')
            .upload(
              fileName,
              avatarFile,
              fileOptions: const FileOptions(upsert: true),
            );

        finalAvatarUrl = _supabase.storage
            .from('avatars')
            .getPublicUrl(fileName);
      }

      // 3. Insert into profiles table
      await _supabase.from('profiles').insert({
        'id': user.id,
        'full_name': fullName,
        'username': username,
        'gender': gender,
        'date_of_birth': dateOfBirth.toIso8601String().split('T').first,
        'nationality': nationality,
        'avatar_url': finalAvatarUrl,
        'bio': '',
      });
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  @override
  Future<void> resetPassword({required String email}) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }
}
