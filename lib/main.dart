import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'providers/providers.dart';
import 'services/services.dart';

// Global flag to check if Firebase is initialized
bool isFirebaseInitialized = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Initialize Firebase with error handling
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyA1QnrmvVwRFa-YMgocUIODqDOage71gVA',
        appId: '1:580779281068:android:ee2b235661db6f02c42d09',
        messagingSenderId: '580779281068',
        projectId: 'recipe-app-5b4e7',
        storageBucket: 'recipe-app-5b4e7.firebasestorage.app',
      ),
    );
    isFirebaseInitialized = true;
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    isFirebaseInitialized = false;
    debugPrint('Firebase initialization failed: $e');
    debugPrint('Running in offline mode');
  }

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const RecipeApp());
}

class RecipeApp extends StatelessWidget {
  const RecipeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Theme provider
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        
        // Auth provider - works with or without Firebase
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        
        // Recipe provider - depends on AuthProvider for userId and userName
        ChangeNotifierProxyProvider<AuthProvider, RecipeProvider>(
          create: (_) => RecipeProvider(),
          update: (_, auth, recipeProvider) {
            recipeProvider?.setUserInfo(auth.userId, auth.user?.username);
            return recipeProvider ?? RecipeProvider();
          },
        ),
        
        // Collection provider - depends on AuthProvider for userId
        ChangeNotifierProxyProvider<AuthProvider, CollectionProvider>(
          create: (_) => CollectionProvider(),
          update: (_, auth, collectionProvider) {
            collectionProvider?.setUserId(auth.userId);
            return collectionProvider ?? CollectionProvider();
          },
        ),
        
        // Shopping list provider - depends on AuthProvider for userId
        ChangeNotifierProxyProvider<AuthProvider, ShoppingListProvider>(
          create: (_) => ShoppingListProvider(),
          update: (_, auth, shoppingProvider) {
            shoppingProvider?.setUserId(auth.userId);
            return shoppingProvider ?? ShoppingListProvider();
          },
        ),
      ],
      child: Consumer2<ThemeProvider, AuthProvider>(
        builder: (context, themeProvider, authProvider, _) {
          return MaterialApp.router(
            title: 'Рецепттер',
            debugShowCheckedModeBanner: false,
            
            // Theme
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.flutterThemeMode,
            
            // Router
            routerConfig: AppRouter.router(authProvider),
          );
        },
      ),
    );
  }
}
