# **Fórmula 1 Prode - Flutter App**

¡Bienvenido al repositorio de la aplicación móvil y web de **Fórmula 1 Prode** desarrollada en **Flutter**!  
Este proyecto te permitirá:

- Registrar y autenticar usuarios.  
- Crear y unirse a torneos privados.  
- Realizar apuestas (poleman, top 10 y DNF) para cada carrera de la Fórmula 1.  
- Recibir notificaciones push acerca de cierres de apuestas y actualizaciones de resultados.  
- Visualizar estadísticas y un ranking general dentro de cada torneo.

---

## **Tabla de Contenidos**

1. [Requisitos Previos](#requisitos-previos)  
2. [Estructura del Proyecto](#estructura-del-proyecto)  
3. [Instalación y Configuración](#instalación-y-configuración)  
4. [Ejecutar la App](#ejecutar-la-app)  
5. [Configuración de Notificaciones Push](#configuración-de-notificaciones-push)  
6. [Contribuciones](#contribuciones)  
7. [Licencia](#licencia)

---

## **Requisitos Previos**

- **Flutter SDK**: Asegúrate de tener la versión estable más reciente de [Flutter](https://docs.flutter.dev/get-started/install).  
- **Dart**: Viene incluido con la instalación de Flutter.  
- **Editor de código**: Puedes usar Visual Studio Code, Android Studio u otro compatible con Flutter.  
- **Dispositivo/Emulador**: Para pruebas en Android, iOS o Web.  
- **Backend**: Un servidor Django (o la URL del servidor) que provea la API REST necesaria para la autenticación, apuestas, torneos, etc.

---

## **Estructura del Proyecto**

La estructura general de este repositorio es la estándar para un proyecto Flutter:

```
f1_prode_flutter/
├── android/
├── ios/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── modules/
│   │   ├── auth/
│   │   ├── home/
│   │   ├── tournaments/
│   │   ├── bets/
│   │   └── notifications/
│   ├── services/
│   │   ├── api_service.dart
│   │   └── ...
│   ├── widgets/
│   └── ...
├── test/
├── web/
├── pubspec.yaml
└── README.md
```

A continuación, una breve descripción de las carpetas más relevantes:

- **lib/main.dart**: Punto de entrada de la aplicación.  
- **lib/modules/**:  
  - **auth**: Lógica y pantallas de inicio de sesión, registro, recuperación de contraseña.  
  - **home**: Pantalla principal, menú, dashboard inicial.  
  - **tournaments**: Pantallas para crear, unirse y ver torneos, rankings, etc.  
  - **bets**: Pantallas relacionadas con las apuestas (poleman, top 10, DNF).  
  - **notifications**: Configuración de notificaciones push y manejo de tokens.  
- **lib/services/**: Contiene clases y métodos para interactuar con el backend (API REST).  
- **widgets**: Componentes reutilizables de la UI.  

---

## **Instalación y Configuración**

1. **Clonar el repositorio**:

   ```bash
   git clone https://github.com/usuario/f1_prode_flutter.git
   cd f1_prode_flutter
   ```

2. **Instalar dependencias**:

   ```bash
   flutter pub get
   ```

3. **Configurar el archivo de entorno** (si se utiliza un archivo `.env` o variables de configuración en `lib/services/api_service.dart`):  
   - Ajusta la URL base de la API del backend.  
   - Configura claves o tokens necesarios para el servicio de notificaciones, si aplica.

4. **Verificar que Flutter esté funcionando**:

   ```bash
   flutter doctor
   ```

   Asegúrate de no tener problemas con las plataformas (Android, iOS, Web).

---

## **Ejecutar la App**

Para **Android** o **iOS** (en un emulador o dispositivo físico):

```bash
flutter run
```

Para **Web** (Chrome):

```bash
flutter run -d chrome
```

> Asegúrate de haber configurado tu navegador o emulador con las credenciales de Firebase (si vas a probar notificaciones web).

---

## **Configuración de Notificaciones Push**

Este proyecto está diseñado para funcionar con **Firebase Cloud Messaging (FCM)** para notificaciones push en Android, iOS y Web. Sigue estos pasos (resumidos) para configurar FCM:

1. Crea un proyecto en la [Consola de Firebase](https://console.firebase.google.com/).  
2. Agrega aplicaciones de Android y iOS a tu proyecto de Firebase.  
3. Descarga los archivos de configuración:  
   - **google-services.json** para Android (colócalo en `android/app/`).  
   - **GoogleService-Info.plist** para iOS (colócalo en `ios/Runner/`).  
4. Agrega la inicialización de Firebase en el `main.dart` (o en un archivo de configuración) si lo requieres.  
5. Para notificaciones en Web, habilita en Firebase el soporte para Web y añade el archivo `firebase-messaging-sw.js` en la carpeta `web/`.

---

## **Contribuciones**

¡Las contribuciones son bienvenidas!  
Si quieres contribuir:

1. Haz un **fork** de este repositorio.  
2. Crea una nueva rama para tu feature/bugfix:  
   ```bash
   git checkout -b feature/mi-nueva-funcionalidad
   ```
3. Realiza tus cambios y escribe pruebas unitarias si es necesario.  
4. Haz commit y push a tu rama:  
   ```bash
   git commit -m "Agrego mi nueva funcionalidad"
   git push origin feature/mi-nueva-funcionalidad
   ```
5. Crea un Pull Request en GitHub.

---

## **Licencia**

Este proyecto está bajo la [MIT License](https://opensource.org/licenses/MIT). Sientete libre de usar, modificar y distribuir el software de acuerdo con los términos de la licencia.  

---  

¡Gracias por usar **Fórmula 1 Prode**! Si tienes alguna duda o sugerencia, no dudes en abrir un **Issue** o comunicarte con el equipo. ¡Felices apuestas y que gane tu corredor favorito!
