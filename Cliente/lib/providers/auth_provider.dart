import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  bool isLoading = false;
  String? errorMessage;

  UserModel? _currentUser;
  bool _isAuthenticated = false;

  static const String _baseUrl = 'https://684495cb71eb5d1be033aad0.mockapi.io';

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  String? get currentUserName => _currentUser?.name;
  String? get currentUserId => _currentUser?.id;

  // Verificar si el usuario está logueado
  bool get canPurchase => _isAuthenticated && _currentUser != null;

  // Iniciar sesión
  Future<bool> login(String username, String password) async {
    if (username.trim().isEmpty || password.trim().isEmpty) {
      errorMessage = 'Por favor completa todos los campos';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final url = Uri.parse('$_baseUrl/users');
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> usersData = jsonDecode(response.body);
        final users =
            usersData.map((user) => UserModel.fromJSON(user)).toList();

        // Buscar usuario por nombre y contraseña
        final user = users.firstWhere(
          (u) =>
              u.name.toLowerCase() == username.toLowerCase() &&
              u.password == password,
          orElse: () => throw Exception('Usuario no encontrado'),
        );

        _currentUser = user;
        _isAuthenticated = true;
        errorMessage = null;

        if (kDebugMode) {
          print('Login exitoso: ${user.name}');
        }

        notifyListeners();
        return true;
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('Usuario no encontrado')) {
        errorMessage = 'Usuario o contraseña incorrectos';
      } else {
        errorMessage = 'Error al iniciar sesión: ${e.toString()}';
      }

      _currentUser = null;
      _isAuthenticated = false;

      if (kDebugMode) {
        print('Error en login: $e');
      }

      notifyListeners();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Registrar nuevo usuario
  Future<bool> register(String username, String password) async {
    if (username.trim().isEmpty || password.trim().isEmpty) {
      errorMessage = 'Por favor completa todos los campos';
      notifyListeners();
      return false;
    }

    if (password.length < 3) {
      errorMessage = 'La contraseña debe tener al menos 3 caracteres';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Primero verificar si el usuario ya existe
      final existingUsers = await _fetchAllUsers();
      final userExists = existingUsers.any(
        (user) => user.name.toLowerCase() == username.toLowerCase(),
      );

      if (userExists) {
        errorMessage = 'El nombre de usuario ya está en uso';
        notifyListeners();
        return false;
      }

      // Crear nuevo usuario
      final newUser = UserModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: username.trim(),
        password: password,
      );

      final url = Uri.parse('$_baseUrl/users');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(newUser.toJSON()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        _currentUser = newUser;
        _isAuthenticated = true;
        errorMessage = null;

        if (kDebugMode) {
          print('Registro exitoso: ${newUser.name}');
        }

        notifyListeners();
        return true;
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      errorMessage = 'Error al registrar usuario: ${e.toString()}';

      if (kDebugMode) {
        print('Error en register: $e');
      }

      notifyListeners();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Obtener todos los usuarios (método auxiliar)
  Future<List<UserModel>> _fetchAllUsers() async {
    final url = Uri.parse('$_baseUrl/users');
    final response = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> usersData = jsonDecode(response.body);
      return usersData.map((user) => UserModel.fromJSON(user)).toList();
    } else {
      throw Exception('Error al obtener usuarios: ${response.statusCode}');
    }
  }

  // Cerrar sesión
  void logout() {
    _currentUser = null;
    _isAuthenticated = false;
    errorMessage = null;

    if (kDebugMode) {
      print('Sesión cerrada');
    }

    notifyListeners();
  }

  // Actualizar perfil del usuario
  Future<bool> updateProfile(String newName, String? newPassword) async {
    if (_currentUser == null || !_isAuthenticated) {
      errorMessage = 'No hay sesión activa';
      notifyListeners();
      return false;
    }

    if (newName.trim().isEmpty) {
      errorMessage = 'El nombre no puede estar vacío';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Verificar si el nuevo nombre ya existe (si es diferente al actual)
      if (newName.toLowerCase() != _currentUser!.name.toLowerCase()) {
        final existingUsers = await _fetchAllUsers();
        final userExists = existingUsers.any(
          (user) =>
              user.name.toLowerCase() == newName.toLowerCase() &&
              user.id != _currentUser!.id,
        );

        if (userExists) {
          errorMessage = 'El nombre de usuario ya está en uso';
          notifyListeners();
          return false;
        }
      }

      // Actualizar usuario
      final updatedUser = _currentUser!.copyWith(
        name: newName.trim(),
        password: newPassword ?? _currentUser!.password,
      );

      final url = Uri.parse('$_baseUrl/users/${_currentUser!.id}');
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updatedUser.toJSON()),
      );

      if (response.statusCode == 200) {
        _currentUser = updatedUser;
        errorMessage = null;

        if (kDebugMode) {
          print('Perfil actualizado: ${updatedUser.name}');
        }

        notifyListeners();
        return true;
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      errorMessage = 'Error al actualizar perfil: ${e.toString()}';

      if (kDebugMode) {
        print('Error en updateProfile: $e');
      }

      notifyListeners();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Verificar si el usuario puede realizar una compra
  String? validatePurchase() {
    if (!_isAuthenticated || _currentUser == null) {
      return 'Debes iniciar sesión para realizar una compra';
    }
    return null;
  }

  // Obtener información del usuario para mostrar en la UI
  Map<String, String> get userInfo {
    if (_currentUser == null) {
      return {'name': 'No autenticado', 'id': ''};
    }
    return {'name': _currentUser!.name, 'id': _currentUser!.id};
  }

  // Limpiar mensaje de error
  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  // Validar sesión (útil para verificar si el usuario sigue siendo válido)
  Future<bool> validateSession() async {
    if (!_isAuthenticated || _currentUser == null) {
      return false;
    }

    try {
      final users = await _fetchAllUsers();
      final userStillExists = users.any((user) => user.id == _currentUser!.id);

      if (!userStillExists) {
        logout();
        return false;
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error validando sesión: $e');
      }
      return false;
    }
  }

  // Eliminar cuenta del usuario
  Future<bool> deleteAccount() async {
    if (_currentUser == null || !_isAuthenticated) {
      errorMessage = 'No hay sesión activa';
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final url = Uri.parse('$_baseUrl/users/${_currentUser!.id}');
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        final userName = _currentUser!.name;
        logout();

        if (kDebugMode) {
          print('Cuenta eliminada: $userName');
        }

        return true;
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      errorMessage = 'Error al eliminar cuenta: ${e.toString()}';

      if (kDebugMode) {
        print('Error en deleteAccount: $e');
      }

      notifyListeners();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
