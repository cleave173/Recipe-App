import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/recipe/recipe_detail_screen.dart';
import '../screens/recipe/add_recipe_screen.dart';
import '../screens/search/search_screen.dart';
import '../screens/favorites/favorites_screen.dart';
import '../screens/collections/collections_screen.dart';
import '../screens/shopping/shopping_list_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/my_recipes_screen.dart';
import '../screens/main_shell.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

  static GoRouter router(AuthProvider authProvider) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/',
      redirect: (context, state) {
        final isLoggedIn = authProvider.isAuthenticated;
        final isLoggingIn = state.matchedLocation == '/login';
        final isRegistering = state.matchedLocation == '/register';

        if (!isLoggedIn && !isLoggingIn && !isRegistering) {
          return '/login';
        }
        if (isLoggedIn && (isLoggingIn || isRegistering)) {
          return '/';
        }
        return null;
      },
      refreshListenable: authProvider,
      routes: [
        // Auth routes
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          name: 'register',
          builder: (context, state) => const RegisterScreen(),
        ),

        // Main shell with bottom navigation
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (context, state, child) => MainShell(child: child),
          routes: [
            GoRoute(
              path: '/',
              name: 'home',
              builder: (context, state) => const HomeScreen(),
            ),
            GoRoute(
              path: '/search',
              name: 'search',
              builder: (context, state) => const SearchScreen(),
            ),
            GoRoute(
              path: '/favorites',
              name: 'favorites',
              builder: (context, state) => const FavoritesScreen(),
            ),
            GoRoute(
              path: '/collections',
              name: 'collections',
              builder: (context, state) => const CollectionsScreen(),
            ),
            GoRoute(
              path: '/profile',
              name: 'profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),

        // Recipe routes (outside shell)
        GoRoute(
          path: '/recipe/:id',
          name: 'recipe_detail',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return RecipeDetailScreen(recipeId: id);
          },
        ),
        GoRoute(
          path: '/add-recipe',
          name: 'add_recipe',
          builder: (context, state) => const AddRecipeScreen(),
        ),
        GoRoute(
          path: '/edit-recipe/:id',
          name: 'edit_recipe',
          builder: (context, state) {
            final id = int.parse(state.pathParameters['id']!);
            return AddRecipeScreen(recipeId: id);
          },
        ),
        GoRoute(
          path: '/shopping-list',
          name: 'shopping_list',
          builder: (context, state) => const ShoppingListScreen(),
        ),
        GoRoute(
          path: '/my-recipes',
          name: 'my_recipes',
          builder: (context, state) => const MyRecipesScreen(),
        ),
      ],
    );
  }
}
