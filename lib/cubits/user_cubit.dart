import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/service.dart';
import 'package:image_picker/image_picker.dart';

abstract class UserState {
  const UserState();
}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class UserAuthenticated extends UserState {
  final UserModel user;
  const UserAuthenticated(this.user);
}

class UserUnauthenticated extends UserState {}

class UserError extends UserState {
  final String message;
  const UserError(this.message);
}

class UserCubit extends Cubit<UserState> {
  UserCubit() : super(UserInitial());

  Future<void> loadSavedUser() async {
    emit(UserLoading());
    try {
      final id = await SupabaseService.getSavedUserId();
      if (id == null) {
        emit(UserUnauthenticated());
        return;
      }
      final user = await SupabaseService.getUserById(id);
      if (user == null) {
        emit(UserUnauthenticated());
        return;
      }
      emit(UserAuthenticated(user));
    } catch (e) {
      emit(UserError('Failed to load user: $e'));
    }
  }

  Future<void> createUser({required String name, XFile? imageFile}) async {
    emit(UserLoading());
    try {
      String? photoUrl;
      if (imageFile != null) {
        try {
          final filename = 'user-${DateTime.now().millisecondsSinceEpoch}.jpg';
          photoUrl = await SupabaseService.uploadProfileImage(
            imageFile,
            filename,
          );
        } catch (e) {
          debugPrint('image upload failed: $e');
        }
      }

      final id = await SupabaseService.createUser(
        name: name,
        photoUrl: photoUrl,
      );
      if (id == null) {
        emit(UserError('Failed to create user'));
        return;
      }
      final user = await SupabaseService.getUserById(id);
      if (user == null) {
        emit(UserError('User created but failed to fetch profile'));
        return;
      }
      emit(UserAuthenticated(user));
    } catch (e) {
      emit(UserError('createUser error: $e'));
    }
  }

  Future<void> logout() async {
    await SupabaseService.clearSavedUserId();
    emit(UserUnauthenticated());
  }
}
