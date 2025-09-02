class Validators {
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  static String? validateUsername(String? username) {
    if (username == null || username.isEmpty) {
      return 'Username is required';
    }
    
    if (username.length < 3) {
      return 'Username must be at least 3 characters long';
    }
    
    if (username.length > 150) {
      return 'Username must be less than 150 characters';
    }
    
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_-]+$');
    if (!usernameRegex.hasMatch(username)) {
      return 'Username can only contain letters, numbers, underscores, and hyphens';
    }
    
    return null;
  }

  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }
    
    if (password.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    
    // Check for at least one number
    if (!RegExp(r'\d').hasMatch(password)) {
      return 'Password must contain at least one number';
    }
    
    // Check for at least one letter
    if (!RegExp(r'[a-zA-Z]').hasMatch(password)) {
      return 'Password must contain at least one letter';
    }
    
    return null;
  }

  static String? validateDriversList(List<String>? drivers, {int expectedCount = 10}) {
    if (drivers == null || drivers.isEmpty) {
      return 'Driver selection is required';
    }
    
    if (drivers.length != expectedCount) {
      return 'Please select exactly $expectedCount drivers';
    }
    
    // Check for duplicates
    final uniqueDrivers = drivers.toSet();
    if (uniqueDrivers.length != drivers.length) {
      return 'Each driver can only be selected once';
    }
    
    // Check that all drivers are non-empty
    if (drivers.any((driver) => driver.trim().isEmpty)) {
      return 'All driver selections must be valid';
    }
    
    return null;
  }

  static String? validateDriver(String? driver) {
    if (driver == null || driver.trim().isEmpty) {
      return 'Driver selection is required';
    }
    return null;
  }

  static String? validateTournamentName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Tournament name is required';
    }
    
    if (name.trim().length < 3) {
      return 'Tournament name must be at least 3 characters long';
    }
    
    if (name.trim().length > 100) {
      return 'Tournament name must be less than 100 characters';
    }
    
    return null;
  }

  static String? validateInviteCode(String? code) {
    if (code == null || code.trim().isEmpty) {
      return 'Invite code is required';
    }
    
    if (code.trim().length < 6) {
      return 'Invite code must be at least 6 characters long';
    }
    
    return null;
  }

  static Map<String, String> validateBetData({
    String? poleman,
    List<String>? top10,
    String? dnf,
    String? fastestLap,
    bool hasSprint = false,
    List<String>? sprintTop10,
  }) {
    final Map<String, String> errors = {};

    final polemanError = validateDriver(poleman);
    if (polemanError != null) {
      errors['poleman'] = polemanError;
    }

    final top10Error = validateDriversList(top10, expectedCount: 10);
    if (top10Error != null) {
      errors['top10'] = top10Error;
    }

    final dnfError = validateDriver(dnf);
    if (dnfError != null) {
      errors['dnf'] = dnfError;
    }

    final fastestLapError = validateDriver(fastestLap);
    if (fastestLapError != null) {
      errors['fastestLap'] = fastestLapError;
    }

    if (hasSprint) {
      final sprintTop10Error = validateDriversList(sprintTop10, expectedCount: 10);
      if (sprintTop10Error != null) {
        errors['sprintTop10'] = sprintTop10Error;
      }
    }

    return errors;
  }

  static String? validatePhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) {
      return null; // Optional field
    }
    
    final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
    if (!phoneRegex.hasMatch(phone.replaceAll(RegExp(r'[\s\-\(\)]'), ''))) {
      return 'Please enter a valid phone number';
    }
    
    return null;
  }

  static String? validateName(String? name, {required String fieldName}) {
    if (name == null || name.trim().isEmpty) {
      return null; // Optional field
    }
    
    if (name.trim().length > 50) {
      return '$fieldName must be less than 50 characters';
    }
    
    final nameRegex = RegExp(r"^[a-zA-ZÀ-ÿ\s\'-]+$");
    if (!nameRegex.hasMatch(name.trim())) {
      return '$fieldName can only contain letters, spaces, hyphens, and apostrophes';
    }
    
    return null;
  }
}