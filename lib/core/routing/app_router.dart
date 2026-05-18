import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/profile/presentation/screens/achievement_detail_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import '../../features/games/puzzle/tic_tac_toe/presentation/screens/tic_tac_toe_screen.dart';
import '../../features/games/puzzle/connect_four/presentation/screens/connect_four_screen.dart';
import '../../features/games/arcade/rps/presentation/screens/rps_screen.dart';
import '../../features/games/arcade/snake/presentation/screens/snake_screen.dart';
import '../../features/games/puzzle/quiz/presentation/screens/quiz_screen.dart';
import '../../features/games/arcade/flappy_bird/presentation/screens/flappy_bird_screen.dart';
import '../../features/games/arcade/pong/presentation/screens/pong_screen.dart';
import '../../features/games/puzzle/memory/presentation/screens/memory_game_screen.dart';
import '../../features/games/puzzle/game_2048/presentation/screens/game_2048_screen.dart';
import '../../features/games/puzzle/typing_battle/presentation/screens/typing_battle_screen.dart';
import '../../features/games/multiplayer/presentation/screens/multiplayer_lobby_screen.dart';
import '../../features/games/strategy/checkers/presentation/screens/checkers_screen.dart';
import '../../features/games/racing/highway/presentation/screens/highway_racing_screen.dart';
import '../../features/games/racing/dodger/presentation/screens/traffic_dodger_screen.dart';
import '../../features/games/action/shooter/presentation/screens/space_shooter_screen.dart';
import '../../features/games/action/runner/presentation/screens/endless_runner_screen.dart';
import '../../features/games/action/slicer/presentation/screens/node_slicer_screen.dart';


final routerProvider = Provider<GoRouter>((ref) {
  final authStateAsync = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final authState = authStateAsync.value;
      final session = authState?.session;
      final isAuth = session != null;

      final isSplash = state.uri.path == '/splash';
      final isLoggingIn = state.uri.path == '/login';
      final isSigningUp = state.uri.path == '/signup';
      final isForgotPassword = state.uri.path == '/forgot-password';
      final isOnboarding = state.uri.path == '/onboarding';

      if (isSplash) return null;

      if (!isAuth) {
        if (!isLoggingIn &&
            !isSigningUp &&
            !isOnboarding &&
            !isForgotPassword) {
          return '/login';
        }
      } else {
        if (isLoggingIn ||
            isSigningUp ||
            isOnboarding ||
            isSplash ||
            isForgotPassword) {
          return '/dashboard';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/achievements',
        builder: (context, state) => const AchievementDetailScreen(),
      ),
      GoRoute(
        path: '/lobby',
        builder: (context, state) => const MultiplayerLobbyScreen(),
      ),

      // Game Routes
      GoRoute(
        path: '/game/tic-tac-toe',
        builder: (context, state) => const TicTacToeScreen(),
      ),
      GoRoute(
        path: '/game/connect-four',
        builder: (context, state) => const ConnectFourScreen(),
      ),
      GoRoute(
        path: '/game/rps',
        builder: (context, state) => const RockPaperScissorsScreen(),
      ),
      GoRoute(
        path: '/game/snake',
        builder: (context, state) => const SnakeScreen(),
      ),
      GoRoute(
        path: '/game/quiz',
        builder: (context, state) => const QuizScreen(),
      ),
      GoRoute(
        path: '/game/typing-battle',
        builder: (context, state) => const TypingBattleScreen(),
      ),
      GoRoute(
        path: '/game/flappy-bird',
        builder: (context, state) => const FlappyBirdScreen(),
      ),
      GoRoute(
        path: '/game/pong',
        builder: (context, state) => const PongScreen(),
      ),
      GoRoute(
        path: '/game/memory',
        builder: (context, state) => const MemoryGameScreen(),
      ),
      GoRoute(
        path: '/game/2048',
        builder: (context, state) => const Game2048Screen(),
      ),
      GoRoute(
        path: '/game/checkers',
        builder: (context, state) => const CheckersScreen(),
      ),
      GoRoute(
        path: '/game/highway-racing',
        builder: (context, state) => const HighwayRacingScreen(),
      ),
      GoRoute(
        path: '/game/traffic-dodger',
        builder: (context, state) => const TrafficDodgerScreen(),
      ),
      GoRoute(
        path: '/game/space-shooter',
        builder: (context, state) => const SpaceShooterScreen(),
      ),
      GoRoute(
        path: '/game/endless-runner',
        builder: (context, state) => const EndlessRunnerScreen(),
      ),
      GoRoute(
        path: '/game/node-slicer',
        builder: (context, state) => const NodeSlicerScreen(),
      ),
    ],
  );
});
