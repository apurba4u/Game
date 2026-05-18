import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  Stream<AuthState> get authStateChanges;
  User? get currentUser;

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
  });

  Future<void> signIn({required String email, required String password});

  Future<void> signOut();

  Future<void> resetPassword({required String email});
}
