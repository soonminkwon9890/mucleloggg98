import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/models/user_profile.dart';

/// 인증 레포지토리 프로바이더
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// 현재 사용자 프로필 프로바이더
final currentProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final repository = ref.watch(authRepositoryProvider);
  return await repository.getCurrentProfile();
});

/// 인증 상태 프로바이더
final authStateProvider = StreamProvider<bool>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
});

