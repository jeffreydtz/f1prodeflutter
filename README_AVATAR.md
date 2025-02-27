# Implementación de Avatares de Usuario en F1 Prode Flutter

Este documento describe la implementación de la funcionalidad de avatares de usuario en la aplicación Flutter F1 Prode.

## Descripción

Se ha implementado la funcionalidad para permitir a los usuarios:
- Seleccionar una imagen de perfil durante el registro
- Ver la imagen de perfil en la pantalla de perfil
- Actualizar la imagen de perfil en la pantalla de edición de perfil

## Requisitos Técnicos

Para utilizar esta funcionalidad, se han añadido las siguientes dependencias al proyecto:

```
flutter pub add image_picker
```

## Componentes Modificados

### 1. Modelo de Usuario

Se ha actualizado el modelo `UserModel` en `lib/models/user.dart` para incluir un campo `avatar` que almacena la URL de la imagen del perfil.

```dart
class UserModel {
  // Campos existentes
  String? avatar;

  UserModel({
    // Parámetros existentes
    this.avatar,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      // Asignaciones existentes
      avatar: json['avatar'],
    );
  }
}
```

### 2. Servicio API

Se ha modificado el servicio `ApiService` en `lib/services/api_service.dart` para:
- Incluir el parámetro `avatarBase64` en el método de registro
- Actualizar los métodos de carga y actualización de perfil para manejar el campo avatar

```dart
// Método de registro actualizado
Future<Map<String, dynamic>> register(
    String username, 
    String email,
    String password, 
    String passwordConfirm,
    {String? avatarBase64}) async {
  // ... código existente
  
  // Añadir el avatar si se proporciona
  if (avatarBase64 != null && avatarBase64.isNotEmpty) {
    requestBody['avatar'] = avatarBase64;
  }
  
  // ... resto del código
}

// Método de actualización de perfil
Future<Map<String, dynamic>> updateUserProfile(Map<String, dynamic> body) async {
  // ... código existente que maneja 'avatar' en el cuerpo de la solicitud
}
```

### 3. Pantalla de Registro

Se ha actualizado la pantalla de registro `lib/screens/register_screen.dart` para:
- Añadir un selector de imágenes
- Convertir la imagen seleccionada a formato base64
- Enviar la imagen junto con los demás datos de registro

```dart
// Seleccionar imagen
Future<void> _selectImage() async {
  final XFile? image = await _picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: 400,
    maxHeight: 400,
    imageQuality: 75,
  );

  if (image != null) {
    final bytes = await image.readAsBytes();
    final base64 = base64Encode(bytes);
    setState(() {
      _selectedImage = bytes;
      _avatarBase64 = 'data:image/${image.name.split('.').last};base64,$base64';
    });
  }
}

// Enviar el avatar en el registro
final response = await _apiService.register(
    username, email, password, passwordConfirm,
    avatarBase64: _avatarBase64);
```

### 4. Pantalla de Perfil

Se ha actualizado la pantalla de perfil `lib/screens/profile_screen.dart` para mostrar la imagen del avatar si existe:

```dart
// Obtener la URL del avatar
final avatarUrl = userData?['avatar'] ?? user?.avatar;

// Mostrar la imagen o las iniciales
avatarUrl != null && avatarUrl.isNotEmpty
    ? CircleAvatar(
        radius: 50,
        backgroundImage: NetworkImage(avatarUrl),
        backgroundColor: Colors.grey[800],
      )
    : CircleAvatar(
        radius: 50,
        backgroundColor: Colors.grey[800],
        child: Text(
          _getInitials(),
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      )
```

### 5. Pantalla de Edición de Perfil

Se ha actualizado la pantalla de edición de perfil `lib/screens/edit_profile_screen.dart` para:
- Mostrar la imagen actual del perfil
- Permitir seleccionar una nueva imagen
- Enviar la nueva imagen en formato base64 cuando se actualiza el perfil

```dart
// Selector de imagen
GestureDetector(
  onTap: _selectImage,
  child: Container(
    // ... código de diseño
    child: _selectedImage != null
        ? ClipOval(child: Image.memory(_selectedImage!))
        : _currentAvatarUrl != null
            ? ClipOval(child: Image.network(_currentAvatarUrl!))
            : Icon(Icons.person),
  ),
)

// Actualizar con nueva imagen
final Map<String, dynamic> updateData = {
  // ... otros campos
};

// Añadir avatar si se ha seleccionado una nueva imagen
if (_avatarBase64 != null) {
  updateData['avatar'] = _avatarBase64;
}
```

## Formato de las Imágenes

Las imágenes se envían al backend como cadenas base64 con el formato:
```
data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD/...
```

## Consideraciones

1. Las imágenes se redimensionan a un máximo de 400x400 píxeles antes de enviarlas al servidor para optimizar el tamaño.
2. Se usa una calidad de compresión del 75% para reducir el tamaño del archivo sin comprometer demasiado la calidad.
3. Si el usuario no selecciona ninguna imagen, se mostrará un avatar con sus iniciales.
4. Los errores relacionados con la imagen (formato incorrecto, tamaño excesivo, etc.) se muestran como mensajes de error.

## Compatibilidad

Esta implementación es compatible con las versiones web, Android e iOS de la aplicación. 