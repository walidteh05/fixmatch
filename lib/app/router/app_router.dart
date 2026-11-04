import 'package:go_router/go_router.dart';

import '../../features/auth/domain/account_type.dart';
import '../../features/auth/presentation/screens/choose_account_type_screen.dart';
import '../../features/auth/presentation/screens/customer_home_screen.dart';
import '../../features/auth/presentation/screens/customer_profile_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_email_screen.dart';
import '../../features/auth/presentation/screens/login_password_screen.dart';
import '../../features/auth/presentation/screens/pending_approval_screen.dart';
import '../../features/auth/presentation/screens/register_email_screen.dart';
import '../../features/auth/presentation/screens/technician_application_screen.dart';
import '../../features/auth/presentation/screens/technician_home_screen.dart';
import '../../features/auth/presentation/screens/welcome_new_member_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import 'app_routes.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/welcome',
  routes: [
    GoRoute(
      path: '/',
      redirect: (context, state) => '/welcome',
    ),
    GoRoute(
      path: '/welcome',
      name: AppRoute.welcome,
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/welcome-new-member',
      name: AppRoute.welcomeNewMember,
      builder: (context, state) {
        final email = state.uri.queryParameters['email'] ?? '';
        return WelcomeNewMemberScreen(email: email);
      },
    ),
    GoRoute(
      path: '/login-email',
      name: AppRoute.loginEmail,
      builder: (context, state) => const LoginEmailScreen(),
    ),
    GoRoute(
      path: '/login-password',
      name: AppRoute.loginPassword,
      builder: (context, state) {
        final email = state.uri.queryParameters['email'] ?? '';
        return LoginPasswordScreen(email: email);
      },
    ),
    GoRoute(
      path: '/register-email',
      name: AppRoute.registerEmail,
      builder: (context, state) => const RegisterEmailScreen(),
    ),
    GoRoute(
      path: '/choose-account-type',
      name: AppRoute.chooseAccountType,
      builder: (context, state) {
        final email = state.uri.queryParameters['email'] ?? '';
        return ChooseAccountTypeScreen(email: email);
      },
    ),
    GoRoute(
      path: '/customer-profile',
      name: AppRoute.customerProfile,
      builder: (context, state) {
        final email = state.uri.queryParameters['email'] ?? '';
        final accountType = AccountType.values.byName(
          state.uri.queryParameters['accountType'] ?? AccountType.customer.name,
        );
        return CustomerProfileScreen(
          email: email,
          accountType: accountType,
        );
      },
    ),
    GoRoute(
      path: '/technician-application',
      name: AppRoute.technicianApplication,
      builder: (context, state) {
        final email = state.uri.queryParameters['email'] ?? '';
        final accountType = AccountType.values.byName(
          state.uri.queryParameters['accountType'] ?? AccountType.technician.name,
        );
        return TechnicianApplicationScreen(
          email: email,
          accountType: accountType,
        );
      },
    ),
    GoRoute(
      path: '/pending-approval',
      name: AppRoute.pendingApproval,
      builder: (context, state) => const PendingApprovalScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      name: AppRoute.forgotPassword,
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/customer-home',
      name: AppRoute.customerHome,
      builder: (context, state) => const CustomerHomeScreen(),
    ),
    GoRoute(
      path: '/technician-home',
      name: AppRoute.technicianHome,
      builder: (context, state) => const TechnicianHomeScreen(),
    ),
  ],
);
