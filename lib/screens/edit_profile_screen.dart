import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfileScreen({Key? key, required this.userData}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  bool _isLoading = false;
  String? _error;
  bool _changePassword = false;
  bool _usernameAvailable = true;
  bool _emailAvailable = true;
  bool _checkingUsername = false;
  bool _checkingEmail = false;

  @override
  void initState() {
    super.initState();
    _usernameController =
        TextEditingController(text: widget.userData['username'] ?? '');
    _emailController =
        TextEditingController(text: widget.userData['email'] ?? '');
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _checkUsernameAvailability(String username) async {
    if (username.isEmpty || username == widget.userData['username']) {
      setState(() {
        _usernameAvailable = true;
        _checkingUsername = false;
      });
      return;
    }

    setState(() {
      _checkingUsername = true;
    });

    try {
      print('Verificando disponibilidad de username: $username');

      // Obtener el ID del usuario actual
      final userId = widget.userData['id']?.toString();

      // Llamar al servicio para verificar disponibilidad
      final isAvailable = await _apiService.checkAvailability(
        'username',
        username,
        currentUserId: userId,
      );

      if (mounted) {
        setState(() {
          _usernameAvailable = isAvailable;
          _checkingUsername = false;
        });
      }
    } catch (e) {
      print('Error al verificar disponibilidad de username: $e');
      if (mounted) {
        setState(() {
          _usernameAvailable = true; // Asumimos disponible en caso de error
          _checkingUsername = false;
        });
      }
    }
  }

  Future<void> _checkEmailAvailability(String email) async {
    if (email.isEmpty || email == widget.userData['email']) {
      setState(() {
        _emailAvailable = true;
        _checkingEmail = false;
      });
      return;
    }

    setState(() {
      _checkingEmail = true;
    });

    try {
      print('Verificando disponibilidad de email: $email');

      // Obtener el ID del usuario actual
      final userId = widget.userData['id']?.toString();

      // Llamar al servicio para verificar disponibilidad
      final isAvailable = await _apiService.checkAvailability(
        'email',
        email,
        currentUserId: userId,
      );

      if (mounted) {
        setState(() {
          _emailAvailable = isAvailable;
          _checkingEmail = false;
        });
      }
    } catch (e) {
      print('Error al verificar disponibilidad de email: $e');
      if (mounted) {
        setState(() {
          _emailAvailable = true; // Asumimos disponible en caso de error
          _checkingEmail = false;
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final Map<String, dynamic> updateData = {
        'username': _usernameController.text,
        'email': _emailController.text,
      };

      // Añadir datos de contraseña si se está cambiando
      if (_changePassword) {
        updateData['current_password'] = _currentPasswordController.text;
        updateData['new_password'] = _newPasswordController.text;
        updateData['new_password_confirm'] = _confirmPasswordController.text;
      }

      print('Actualizando perfil con datos: $updateData');

      // Llamar al servicio para actualizar el perfil
      final result = await _apiService.updateUserProfile(updateData);

      if (mounted) {
        if (result['success'] == true) {
          // Mostrar mensaje de éxito
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Perfil actualizado correctamente'),
              backgroundColor: Colors.green,
            ),
          );

          // Si se actualizó la contraseña, mostrar mensaje adicional
          if (result['password_updated'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Contraseña actualizada correctamente'),
                backgroundColor: Colors.green,
              ),
            );
          }

          // Volver a la pantalla anterior
          Navigator.pop(context, result['profile']);
        } else {
          // Mostrar errores
          setState(() {
            _isLoading = false;
            _error =
                result['errors']?.toString() ?? 'Error al actualizar el perfil';
          });
        }
      }
    } catch (e) {
      print('Error al actualizar perfil: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _updateProfile,
            tooltip: 'Guardar cambios',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color.fromARGB(255, 255, 17, 0),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        margin: const EdgeInsets.only(bottom: 16.0),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: Colors.red),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),

                    // Sección de información básica
                    const Text(
                      'Información básica',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Campo de nombre de usuario
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Nombre de usuario',
                        hintText: 'Ingrese su nombre de usuario',
                        prefixIcon: const Icon(Icons.person),
                        suffixIcon: _checkingUsername
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : _usernameController.text.isNotEmpty &&
                                    _usernameController.text !=
                                        widget.userData['username']
                                ? Icon(
                                    _usernameAvailable
                                        ? Icons.check_circle
                                        : Icons.error,
                                    color: _usernameAvailable
                                        ? Colors.green
                                        : Colors.red,
                                  )
                                : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese un nombre de usuario';
                        }
                        if (!_usernameAvailable) {
                          return 'Este nombre de usuario ya está en uso';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        _checkUsernameAvailability(value);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Campo de correo electrónico
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Correo electrónico',
                        hintText: 'Ingrese su correo electrónico',
                        prefixIcon: const Icon(Icons.email),
                        suffixIcon: _checkingEmail
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : _emailController.text.isNotEmpty &&
                                    _emailController.text !=
                                        widget.userData['email']
                                ? Icon(
                                    _emailAvailable
                                        ? Icons.check_circle
                                        : Icons.error,
                                    color: _emailAvailable
                                        ? Colors.green
                                        : Colors.red,
                                  )
                                : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor ingrese un correo electrónico';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(value)) {
                          return 'Por favor ingrese un correo electrónico válido';
                        }
                        if (!_emailAvailable) {
                          return 'Este correo electrónico ya está en uso';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        _checkEmailAvailability(value);
                      },
                    ),
                    const SizedBox(height: 24),

                    // Sección de cambio de contraseña
                    Row(
                      children: [
                        const Text(
                          'Cambiar contraseña',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Switch(
                          value: _changePassword,
                          onChanged: (value) {
                            setState(() {
                              _changePassword = value;
                            });
                          },
                          activeColor: const Color.fromARGB(255, 255, 17, 0),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (_changePassword) ...[
                      // Campo de contraseña actual
                      TextFormField(
                        controller: _currentPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Contraseña actual',
                          hintText: 'Ingrese su contraseña actual',
                          prefixIcon: const Icon(Icons.lock),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese su contraseña actual';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Campo de nueva contraseña
                      TextFormField(
                        controller: _newPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Nueva contraseña',
                          hintText: 'Ingrese su nueva contraseña',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingrese una nueva contraseña';
                          }
                          if (value.length < 8) {
                            return 'La contraseña debe tener al menos 8 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Campo de confirmación de nueva contraseña
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Confirmar nueva contraseña',
                          hintText: 'Confirme su nueva contraseña',
                          prefixIcon: const Icon(Icons.lock_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor confirme su nueva contraseña';
                          }
                          if (value != _newPasswordController.text) {
                            return 'Las contraseñas no coinciden';
                          }
                          return null;
                        },
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Botón de guardar cambios
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 255, 17, 0),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: const Text(
                          'GUARDAR CAMBIOS',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
