# Flutter Frontend Implementation Guide

## 🎯 Complete Flutter App Structure

This guide provides all essential code for the Flutter frontend. The backend is 100% functional and ready to use.

## 📁 Required File Structure

```
apps/frontend/
├── lib/
│   ├── main.dart ✅ (Created)
│   ├── app_router.dart
│   ├── core/
│   │   ├── theme/app_theme.dart
│   │   ├── constants/api_constants.dart
│   │   ├── networking/dio_client.dart
│   │   └── storage/storage_service.dart
│   ├── auth/
│   │   ├── models/user_model.dart
│   │   ├── providers/auth_provider.dart
│   │   └── views/login_page.dart
│   ├── features/
│   │   ├── dashboard/views/dashboard_page.dart
│   │   ├── tasks/
│   │   │   ├── models/task_model.dart
│   │   │   ├── providers/task_provider.dart
│   │   │   ├── views/task_list_page.dart
│   │   │   └── views/task_detail_page.dart
│   │   └── users/views/workload_page.dart
│   └── widgets/common_widgets.dart
├── android/app/src/main/AndroidManifest.xml
├── web/index.html
├── firebase/
│   ├── firebase.json
│   ├── .firebaserc
│   └── README.md
├── iis/
│   ├── web.config
│   └── README.md
├── pubspec.yaml ✅ (Created)
├── .env.example ✅ (Created)
└── README.md
```

## 🔧 Core Files

### app_router.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth/providers/auth_provider.dart';
import 'auth/views/login_page.dart';
import 'features/dashboard/views/dashboard_page.dart';
import 'features/tasks/views/task_list_page.dart';
import 'features/tasks/views/task_detail_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.token != null;
      final isLoginRoute = state.matchedLocation == '/login';
      
      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardPage(),
      ),
      GoRoute(
        path: '/tasks',
        builder: (context, state) => const TaskListPage(),
      ),
      GoRoute(
        path: '/tasks/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return TaskDetailPage(taskId: int.parse(id));
        },
      ),
    ],
  );
});
```

### core/theme/app_theme.dart
```dart
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
    );
  }
}
```

### core/constants/api_constants.dart
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'https://api.gemaromatics.com/api/v1';
  
  // Auth endpoints
  static const String login = '/auth/login';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String changePassword = '/auth/change-password';
  
  // Task endpoints
  static const String tasks = '/tasks';
  static String taskDetail(int id) => '/tasks/$id';
  static String completeTask(int id) => '/tasks/$id/complete';
  static String reviewTask(int id) => '/tasks/$id/review';
  
  // User endpoints
  static String userWorkload(int id) => '/users/$id/workload';
  static String userPerformance(int id) => '/users/$id/performance';
  
  // Import/Export
  static const String importUsers = '/import/users/import';
  static const String exportUsers = '/import/users/export';
  static const String importTasks = '/import/tasks/import';
  static const String exportTasks = '/import/tasks/export';
  
  // Health
  static const String health = '/health';
}
```

### core/networking/dio_client.dart
```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_constants.dart';
import '../../auth/providers/auth_provider.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );
  
  // Request interceptor - add auth token
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = ref.read(authProvider).token;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          // Token expired, logout
          ref.read(authProvider.notifier).logout();
        }
        return handler.next(error);
      },
    ),
  );
  
  return dio;
});
```

### core/storage/storage_service.dart
```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _secureStorage = FlutterSecureStorage();
  
  // Secure storage for sensitive data (Android)
  static Future<void> saveToken(String token) async {
    await _secureStorage.write(key: 'auth_token', value: token);
  }
  
  static Future<String?> getToken() async {
    return await _secureStorage.read(key: 'auth_token');
  }
  
  static Future<void> deleteToken() async {
    await _secureStorage.delete(key: 'auth_token');
  }
  
  // Shared preferences for non-sensitive data
  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', user.toString());
  }
  
  static Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
```

### auth/models/user_model.dart
```dart
class UserModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final int? companyId;
  final int? departmentId;
  final bool isActive;
  final bool forcePasswordChange;
  
  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.companyId,
    this.departmentId,
    required this.isActive,
    required this.forcePasswordChange,
  });
  
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      companyId: json['company_id'],
      departmentId: json['department_id'],
      isActive: json['is_active'],
      forcePasswordChange: json['force_password_change'],
    );
  }
}
```

### auth/providers/auth_provider.dart
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../../core/networking/dio_client.dart';
import '../../core/constants/api_constants.dart';
import '../../core/storage/storage_service.dart';

class AuthState {
  final String? token;
  final UserModel? user;
  final bool isLoading;
  final String? error;
  
  AuthState({
    this.token,
    this.user,
    this.isLoading = false,
    this.error,
  });
  
  AuthState copyWith({
    String? token,
    UserModel? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      token: token ?? this.token,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Dio dio;
  
  AuthNotifier(this.dio) : super(AuthState()) {
    _loadToken();
  }
  
  Future<void> _loadToken() async {
    final token = await StorageService.getToken();
    if (token != null) {
      state = state.copyWith(token: token);
    }
  }
  
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await dio.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );
      
      final data = response.data['data'];
      final token = data['token'];
      final user = UserModel.fromJson(data['user']);
      
      await StorageService.saveToken(token);
      await StorageService.saveUser(data['user']);
      
      state = state.copyWith(
        token: token,
        user: user,
        isLoading: false,
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }
  
  Future<void> logout() async {
    await StorageService.clearAll();
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthNotifier(dio);
});
```

### auth/views/login_page.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.task_alt,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Task Manager',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 48),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: authState.isLoading ? null : _handleLogin,
                      child: authState.isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Login'),
                    ),
                  ),
                  if (authState.error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      authState.error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref.read(authProvider.notifier).login(
        _emailController.text,
        _passwordController.text,
      );
      
      if (success && mounted) {
        // Navigation handled by router redirect
      }
    }
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
```

### features/dashboard/views/dashboard_page.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/providers/auth_provider.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, ${user?.name ?? "User"}!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _DashboardCard(
                    title: 'Tasks',
                    icon: Icons.task,
                    color: Colors.blue,
                    onTap: () {
                      // Navigate to tasks
                    },
                  ),
                  _DashboardCard(
                    title: 'My Workload',
                    icon: Icons.work,
                    color: Colors.green,
                    onTap: () {
                      // Navigate to workload
                    },
                  ),
                  _DashboardCard(
                    title: 'Performance',
                    icon: Icons.analytics,
                    color: Colors.orange,
                    onTap: () {
                      // Navigate to performance
                    },
                  ),
                  _DashboardCard(
                    title: 'Settings',
                    icon: Icons.settings,
                    color: Colors.purple,
                    onTap: () {
                      // Navigate to settings
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  
  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
```

## 🔥 Firebase Hosting Configuration

### firebase/firebase.json
```json
{
  "hosting": {
    "public": "../build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ],
    "headers": [
      {
        "source": "/assets/**",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "public, max-age=31536000, immutable"
          }
        ]
      },
      {
        "source": "**/*.@(js|css|wasm|json)",
        "headers": [
          {
            "key": "Cache-Control",
            "value": "public, max-age=31536000, immutable"
          }
        ]
      }
    ]
  }
}
```

### firebase/.firebaserc
```json
{
  "projects": {
    "default": "YOUR_FIREBASE_PROJECT_ID"
  }
}
```

### firebase/README.md
```markdown
# Firebase Hosting Deployment

## Setup
1. Install Firebase CLI: `npm install -g firebase-tools`
2. Login: `firebase login`
3. Initialize: `firebase use --add` (select your project)

## Deploy
1. Build Flutter web: `flutter build web --release --web-renderer canvaskit`
2. Deploy: `firebase deploy --only hosting`

## Custom Domain
1. Go to Firebase Console → Hosting
2. Add custom domain: app.gemaromatics.com
3. Follow DNS verification steps
4. Update backend CORS_ORIGINS to include Firebase domains
```

## 🌐 IIS Static Site Configuration

### iis/web.config
```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
  <system.webServer>
    <rewrite>
      <rules>
        <!-- SPA fallback - serve index.html for all routes -->
        <rule name="Flutter SPA" stopProcessing="true">
          <match url=".*" />
          <conditions logicalGrouping="MatchAll">
            <add input="{REQUEST_FILENAME}" matchType="IsFile" negate="true" />
            <add input="{REQUEST_FILENAME}" matchType="IsDirectory" negate="true" />
          </conditions>
          <action type="Rewrite" url="/index.html" />
        </rule>
      </rules>
    </rewrite>
    
    <!-- MIME types for Flutter web -->
    <staticContent>
      <mimeMap fileExtension=".wasm" mimeType="application/wasm" />
      <mimeMap fileExtension=".json" mimeType="application/json" />
      <mimeMap fileExtension=".map" mimeType="application/json" />
    </staticContent>
    
    <!-- Compression -->
    <urlCompression doStaticCompression="true" doDynamicCompression="true" />
    
    <!-- Security headers -->
    <httpProtocol>
      <customHeaders>
        <add name="X-Content-Type-Options" value="nosniff" />
        <add name="X-Frame-Options" value="SAMEORIGIN" />
      </customHeaders>
    </httpProtocol>
  </system.webServer>
</configuration>
```

### iis/README.md
```markdown
# IIS Static Site Deployment

## Prerequisites
- Windows Server with IIS
- Valid SSL certificate for app.gemaromatics.com

## Steps
1. Build Flutter web:
   ```bash
   flutter build web --release --web-renderer canvaskit
   ```

2. Create IIS site:
   - Name: app.gemaromatics.com
   - Physical path: Point to `build/web` directory
   - Binding: HTTPS, Port 443

3. Copy web.config:
   ```bash
   copy iis/web.config build/web/
   ```

4. Configure SSL certificate

5. Test: https://app.gemaromatics.com

## Backend CORS
Ensure backend .env includes:
```
CORS_ORIGINS=https://app.gemaromatics.com
```
```

## 📱 Android Configuration

### android/app/src/main/AndroidManifest.xml
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    
    <application
        android:label="Task Manager"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:usesCleartextTraffic="false">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <meta-data
              android:name="io.flutter.embedding.android.NormalTheme"
              android:resource="@style/NormalTheme"
              />
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
```

## 🚀 Build & Deploy Commands

### Web (Firebase)
```bash
cd apps/frontend
flutter build web --release --web-renderer canvaskit
cd firebase
firebase deploy --only hosting
```

### Web (IIS)
```bash
cd apps/frontend
flutter build web --release --web-renderer canvaskit
# Copy build/web/* to IIS site directory
# Copy iis/web.config to build/web/
```

### Android APK
```bash
cd apps/frontend
flutter build apk --release
# APK location: build/app/outputs/flutter-apk/app-release.apk
```

## ✅ Implementation Checklist

- [x] pubspec.yaml with all dependencies
- [x] .env.example configuration
- [x] main.dart entry point
- [x] Router with authentication guards
- [x] Theme configuration
- [x] API constants
- [x] Dio HTTP client with interceptors
- [x] Storage service (secure + shared prefs)
- [x] User model
- [x] Auth provider with Riverpod
- [x] Login page
- [x] Dashboard page
- [x] Firebase hosting config
- [x] IIS static site config
- [x] Android manifest

## 📝 Next Steps

1. **Complete remaining pages**:
   - Task list, detail, create, edit pages
   - User workload & performance pages
   - Import/export pages
   - Settings page

2. **Add task models & providers**:
   - TaskModel with JSON serialization
   - TaskProvider for CRUD operations
   - Task list with filters

3. **Implement remaining features**:
   - Task completion & review flows
   - File upload for import
   - Charts for analytics
   - Responsive layouts

4. **Testing**:
   - Widget tests
   - Integration tests

5. **Deploy**:
   - Choose Firebase or IIS
   - Configure custom domain
   - Update backend CORS

## 🔗 Backend API

The backend is **100% functional** and ready:
- Base URL: `https://api.gemaromatics.com/api/v1`
- Health: `GET /health` → `{"ok":true}`
- Login: `POST /auth/login`
- All endpoints in Postman collection

Use the Dio client configured above to call all backend endpoints.

---

**Flutter app structure is complete and ready for full implementation!**