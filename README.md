# IdentityConnect Mobile App

## Development Setup

> ⚠️ **Development Note**: Security checks are temporarily disabled to allow simulator testing. DO NOT deploy to production with these checks disabled.

### Simulator/Emulator Restrictions
For security reasons, certain features are restricted or disabled when running the app in a simulator/emulator:

- **Device Security Checks**: The app includes jailbreak/root detection and other security measures that are bypassed in simulator/emulator environments for development purposes.
- **Biometric Authentication**: Biometric features are disabled in simulator/emulator environments.
- **Production Mode**: In production builds, the app will not run on simulators/emulators.

### Running in Development Mode

To run the app in development mode with simulator/emulator restrictions bypassed:

```bash
flutter run --debug
```

### Environment-specific Behaviors

#### Simulator/Emulator (Development Only)
- Device security checks are bypassed
- Biometric authentication is disabled
- Device registration flow can be tested without security restrictions

#### Physical Device
- Full security checks enabled
- Biometric authentication available
- Device registration enforced
- Jailbreak/root detection active

### Security Features

The app implements several security measures:
- Device integrity verification
- Jailbreak/root detection
- Secure storage for sensitive data
- Biometric authentication
- Device registration and verification

⚠️ **Important Notes**:
1. Always test security-critical features on physical devices
2. Simulator/emulator usage is for UI/UX development only
3. Production builds will enforce all security measures
4. Some features may not be available or may behave differently in simulator/emulator environments

### Required Setup

1. Flutter SDK version: ^3.8.0
2. Dependencies:
   ```yaml
   flutter_jailbreak_detection: ^1.10.0
   local_auth: ^2.1.6
   flutter_secure_storage: ^9.0.0
   ```

### Testing Guidelines

1. **Development Testing (Simulator/Emulator)**:
   - Basic UI flows
   - Navigation
   - Non-security dependent features

2. **Security Testing (Physical Device Only)**:
   - Biometric authentication
   - Device registration
   - Security checks
   - Token handling

### Known Development Limitations

1. **Simulator/Emulator**:
   - No biometric authentication
   - Security checks are bypassed
   - Device registration uses mock data

2. **Physical Device Requirements**:
   - Non-jailbroken/non-rooted device
   - Biometric capability
   - Developer mode disabled (iOS)
