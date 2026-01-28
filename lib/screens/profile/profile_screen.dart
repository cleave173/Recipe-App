import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../l10n/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.profile),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final user = auth.user;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Profile header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          user?.username.substring(0, 1).toUpperCase() ?? '?',
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user?.username ?? 'Пайдаланушы',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                    if (user?.isAdmin ?? false) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Админ',
                          style: TextStyle(
                            color: AppColors.primaryLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // My Recipes
              _buildMenuItem(
                context,
                icon: Icons.restaurant_menu_rounded,
                title: AppStrings.myRecipes,
                onTap: () => context.push('/my-recipes'),
              ),
              
              const SizedBox(height: 24),
              Text(
                AppStrings.settings,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 12),

              // Theme
              Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) {
                  return _buildMenuItem(
                    context,
                    icon: themeProvider.isDarkMode
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    title: AppStrings.theme,
                    trailing: DropdownButton<AppThemeMode>(
                      value: themeProvider.themeMode,
                      underline: const SizedBox(),
                      items: AppThemeMode.values.map((mode) {
                        return DropdownMenuItem(
                          value: mode,
                          child: Text(mode.nameKk),
                        );
                      }).toList(),
                      onChanged: (mode) {
                        if (mode != null) {
                          themeProvider.setThemeMode(mode);
                        }
                      },
                    ),
                  );
                },
              ),

              // Language
              _buildMenuItem(
                context,
                icon: Icons.language_rounded,
                title: AppStrings.language,
                trailing: const Text('Қазақша'),
              ),

              // Change password
              _buildMenuItem(
                context,
                icon: Icons.lock_outline_rounded,
                title: AppStrings.changePassword,
                onTap: () {
                  // Show change password dialog
                },
              ),

              const SizedBox(height: 24),
              Text(
                AppStrings.about,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
              const SizedBox(height: 12),

              // Version
              _buildMenuItem(
                context,
                icon: Icons.info_outline_rounded,
                title: AppStrings.version,
                trailing: const Text('1.0.0'),
              ),

              // Privacy Policy
              _buildMenuItem(
                context,
                icon: Icons.privacy_tip_outlined,
                title: AppStrings.privacyPolicy,
                onTap: () => _showPrivacyPolicy(context),
              ),

              // Terms
              _buildMenuItem(
                context,
                icon: Icons.description_outlined,
                title: AppStrings.termsOfService,
                onTap: () => _showTermsOfService(context),
              ),

              // Admin panel (if admin)
              if (user?.isAdmin ?? false) ...[
                const SizedBox(height: 24),
                Text(
                  AppStrings.adminPanel,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 12),
                _buildMenuItem(
                  context,
                  icon: Icons.people_outline_rounded,
                  title: AppStrings.userManagement,
                  color: AppColors.primaryLight,
                  onTap: () {},
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.category_outlined,
                  title: AppStrings.categoryManagement,
                  color: AppColors.primaryLight,
                  onTap: () {},
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.analytics_outlined,
                  title: AppStrings.statistics,
                  color: AppColors.primaryLight,
                  onTap: () {},
                ),
              ],

              const SizedBox(height: 32),

              // Logout button
              ElevatedButton.icon(
                onPressed: () => _showLogoutConfirmation(context),
                icon: const Icon(Icons.logout_rounded),
                label: Text(AppStrings.logout),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    Widget? trailing,
    Color? color,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final iconColor = color ?? theme.colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(title),
        trailing: trailing ?? (onTap != null
            ? const Icon(Icons.chevron_right_rounded)
            : null),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppStrings.logout),
        content: Text(AppStrings.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await context.read<AuthProvider>().logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(AppStrings.logout),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text(AppStrings.privacyPolicy),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Құпиялылық саясаты',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Соңғы жаңартылған күні: 2024 жыл',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                _buildPolicySection(
                  context,
                  'Жалпы мәліметтер',
                  'Біздің қосымшамыз сіздің жеке деректеріңіздің қауіпсіздігін қамтамасыз етеді. '
                  'Біз тек қызмет көрсету үшін қажетті ақпаратты жинаймыз және сақтаймыз.',
                ),
                _buildPolicySection(
                  context,
                  'Жиналатын деректер',
                  '• Email мекенжайы (тіркелу үшін)\n'
                  '• Пайдаланушы аты\n'
                  '• Сіз қосқан рецепттер\n'
                  '• Таңдаулылар тізімі\n'
                  '• Қосымша баптаулары',
                ),
                _buildPolicySection(
                  context,
                  'Деректерді пайдалану',
                  'Сіздің деректеріңіз тек қосымшаның жұмысын қамтамасыз ету үшін қолданылады. '
                  'Біз сіздің деректеріңізді үшінші тараптарға бермейміз.',
                ),
                _buildPolicySection(
                  context,
                  'Деректерді қорғау',
                  'Барлық деректер Firebase серверлерінде шифрланған түрде сақталады. '
                  'Біз заманауи қауіпсіздік стандарттарын қолданамыз.',
                ),
                _buildPolicySection(
                  context,
                  'Байланыс',
                  'Сұрақтарыңыз болса, бізбен байланысыңыз:\nrecipeapp.kz@gmail.com',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTermsOfService(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text(AppStrings.termsOfService),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Қызмет көрсету шарттары',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Соңғы жаңартылған күні: 2024 жыл',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                _buildPolicySection(
                  context,
                  '1. Қызметті қабылдау',
                  'Осы қосымшаны пайдалану арқылы сіз осы шарттармен келісесіз. '
                  'Егер келіспесеңіз, қосымшаны пайдаланбаңыз.',
                ),
                _buildPolicySection(
                  context,
                  '2. Тіркелу',
                  '• Тіркелу үшін нақты ақпарат беру қажет\n'
                  '• Аккаунтыңыздың қауіпсіздігіне жауаптысыз\n'
                  '• Құпия сөзіңізді құпия сақтаңыз',
                ),
                _buildPolicySection(
                  context,
                  '3. Контент',
                  '• Сіз қосқан рецепттер заңды болуы керек\n'
                  '• Авторлық құқықты бұзуға болмайды\n'
                  '• Зиянды немесе қате ақпарат жариялауға болмайды',
                ),
                _buildPolicySection(
                  context,
                  '4. Шектеулер',
                  '• Қосымшаны заңсыз мақсаттарға пайдалануға болмайды\n'
                  '• Басқа пайдаланушыларға зиян келтіруге болмайды\n'
                  '• Спам және жарнама жіберуге болмайды',
                ),
                _buildPolicySection(
                  context,
                  '5. Жауапкершілік',
                  'Қосымша "сол қалпында" ұсынылады. Біз рецепттердің дұрыстығына '
                  'кепілдік бермейміз. Пайдаланушылар өз рецепттеріне жауапты.',
                ),
                _buildPolicySection(
                  context,
                  '6. Өзгерістер',
                  'Біз осы шарттарды кез келген уақытта өзгерте аламыз. '
                  'Өзгерістер туралы қосымша арқылы хабарлаймыз.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPolicySection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
