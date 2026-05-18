import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/common_widgets/glass_container.dart';
import '../../../../core/common_widgets/cyber_button.dart';
import '../../../../core/common_widgets/cyber_text_field.dart';
import '../../../../core/utils/validation_utils.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/profile_provider.dart';
import '../../../dashboard/presentation/providers/stats_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _editFormKey = GlobalKey<FormState>();

  // Pre-designed Cyberpunk avatar lists
  final List<Map<String, String>> _cyberAvatars = [
    {
      'name': 'Hacker',
      'url': 'https://api.dicebear.com/7.x/bottts/png?seed=Hacker&mouth=smile&eyes=sensor'
    },
    {
      'name': 'Netrunner',
      'url': 'https://api.dicebear.com/7.x/pixel-art/png?seed=Netrunner'
    },
    {
      'name': 'Ninja',
      'url': 'https://api.dicebear.com/7.x/bottts-neutral/png?seed=Ninja&eyes=bulging'
    },
    {
      'name': 'Grid AI',
      'url': 'https://api.dicebear.com/7.x/identicon/png?seed=GridAI'
    },
    {
      'name': 'Chrome Robot',
      'url': 'https://api.dicebear.com/7.x/bottts/png?seed=ChromeRobot&eyes=closed'
    },
    {
      'name': 'Neon Rider',
      'url': 'https://api.dicebear.com/7.x/pixel-art/png?seed=NeonRider'
    },
  ];

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final statsAsync = ref.watch(statsProvider);

    return profileAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: AppTheme.cyanBlue,
        ),
      ),
      error: (err, stack) => Center(
        child: Text(
          'PROFILE OFFLINE: $err',
          style: const TextStyle(color: AppTheme.electricPink, fontWeight: FontWeight.bold),
        ),
      ),
      data: (profile) {
        final activeBanner = ref.read(userProfileProvider.notifier).activeBanner;
        final bannerList = ref.read(userProfileProvider.notifier).banners;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Customizable Cyberpunk Profile Banner
              GestureDetector(
                onTap: () {
                  _showBannerSelector(context, bannerList, profile.bannerTheme);
                },
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: activeBanner.colors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: activeBanner.colors.first, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: activeBanner.colors.first.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(activeBanner.icon, color: Colors.white, size: 48)
                            .animate(onPlay: (controller) => controller.repeat(reverse: true))
                            .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 2.seconds)
                            .blur(begin: const Offset(0, 0), end: const Offset(1, 1), duration: 2.seconds),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.style, color: Colors.white70, size: 10),
                              SizedBox(width: 4),
                              Text(
                                'CHANGE THEME',
                                style: TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // User Avatar & Title Info
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: activeBanner.colors.first,
                    child: CircleAvatar(
                      radius: 38,
                      backgroundImage: NetworkImage(profile.avatarUrl),
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.username.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.wifi, color: Colors.green, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              'NEURAL STREAM: ONLINE | STREAK: ${profile.streakCount}D',
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppTheme.cyanBlue),
                    onPressed: () => _showEditProfileModal(context, profile),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Core Stats Hub
              const Text(
                'GRID RANK STATUS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 12),
              statsAsync.maybeWhen(
                data: (stats) => GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn('XP LEVEL', 'LVL ${stats.level}', AppTheme.cyanBlue),
                      _buildStatColumn(
                        'ACHIEVEMENTS',
                        '${stats.totalTrophies} / 24',
                        AppTheme.neonPurple,
                      ),
                      _buildStatColumn('XP BANK', '${stats.currentXp}', Colors.amber),
                    ],
                  ),
                ),
                orElse: () => GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatColumn('XP LEVEL', 'LVL 1', AppTheme.cyanBlue),
                      _buildStatColumn(
                        'ACHIEVEMENTS',
                        '0 / 24',
                        AppTheme.neonPurple,
                      ),
                      _buildStatColumn('XP BANK', '0', Colors.amber),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Identity Archive Full Information
              const Text(
                'IDENTITY CREDENTIALS ARCHIVE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 12),
              GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildIdentityRow('FULL IDENTITY', profile.fullName),
                    const Divider(color: Colors.white10),
                    _buildIdentityRow('NEURAL EMAIL', profile.email),
                    const Divider(color: Colors.white10),
                    _buildIdentityRow('GENDER REF', profile.gender),
                    const Divider(color: Colors.white10),
                    _buildIdentityRow('HOMELAND REGION', profile.nationality),
                    const Divider(color: Colors.white10),
                    _buildIdentityRow(
                      'GRID DESCENT',
                      profile.dateOfBirth == null
                          ? 'UNKNOWN'
                          : '${profile.dateOfBirth!.year}-${profile.dateOfBirth!.month.toString().padLeft(2, '0')}-${profile.dateOfBirth!.day.toString().padLeft(2, '0')}',
                    ),
                    const Divider(color: Colors.white10),
                    _buildIdentityRow('FAV SIMULATION', profile.favoriteGame),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Interactive Bio Panel
              const Text(
                'MEMORANDUM (BIO)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Text(
                  profile.bio.isEmpty
                      ? 'No personal log archived.'
                      : profile.bio,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Terminal Preferences
              const Text(
                'TERMINAL PREFERENCES',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CyberButton(
                      text: 'SETTINGS',
                      icon: Icons.settings,
                      isSecondary: true,
                      onPressed: () => context.push('/settings'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CyberButton(
                      text: 'ARCHIVE',
                      icon: Icons.emoji_events,
                      isSecondary: true,
                      onPressed: () => context.push('/achievements'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              CyberButton(
                text: 'MULTIPLAYER RADAR',
                icon: Icons.radar,
                onPressed: () => context.push('/lobby'),
              ),
              const SizedBox(height: 24),

              CyberButton(
                text: 'TERMINATE CONNECTION',
                icon: Icons.power_settings_new,
                isSecondary: true,
                onPressed: () {
                  ref.read(authControllerProvider.notifier).signOut();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatColumn(String title, String val, Color highlight) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 9,
            color: Colors.white54,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          val,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: highlight,
          ),
        ),
      ],
    );
  }

  Widget _buildIdentityRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white54,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showBannerSelector(BuildContext context, List<CyberpunkBanner> banners, String currentTheme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.darkBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return GlassContainer(
          borderRadius: 20,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'SELECT CYBERPUNK THEME',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: banners.length,
                itemBuilder: (context, index) {
                  final banner = banners[index];
                  final isSelected = banner.name == currentTheme;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () {
                        ref.read(userProfileProvider.notifier).updateBannerTheme(banner.name);
                        Navigator.pop(context);
                      },
                      child: GlassContainer(
                        borderColor: isSelected ? AppTheme.cyanBlue : AppTheme.glassBorder,
                        backgroundColor: isSelected
                            ? AppTheme.cyanBlue.withOpacity(0.05)
                            : AppTheme.glassBackground,
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                gradient: LinearGradient(
                                  colors: banner.colors,
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Icon(banner.icon, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              banner.name.toUpperCase(),
                              style: TextStyle(
                                color: isSelected ? AppTheme.cyanBlue : Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const Spacer(),
                            if (isSelected)
                              const Icon(Icons.check, color: AppTheme.cyanBlue),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditProfileModal(BuildContext context, UserProfile profile) {
    final nameController = TextEditingController(text: profile.fullName);
    final tagController = TextEditingController(text: profile.username);
    final nationController = TextEditingController(text: profile.nationality);
    final bioController = TextEditingController(text: profile.bio);
    final urlController = TextEditingController(text: profile.avatarUrl);

    String selectedGender = profile.gender;
    DateTime? dob = profile.dateOfBirth;
    String favoriteGame = profile.favoriteGame;
    String selectedAvatarUrl = profile.avatarUrl;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.darkBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 24,
                left: 24,
                right: 24,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _editFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'EDIT ARCHIVE DATA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),

                      // Dynamic Avatar Selector
                      const Text(
                        'SELECT NEURAL AVATAR',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 70,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _cyberAvatars.length,
                          itemBuilder: (context, index) {
                            final av = _cyberAvatars[index];
                            final isSel = selectedAvatarUrl == av['url'];

                            return GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  selectedAvatarUrl = av['url']!;
                                  urlController.text = av['url']!;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isSel ? AppTheme.cyanBlue : Colors.transparent,
                                    width: 2,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: CircleAvatar(
                                  radius: 28,
                                  backgroundColor: AppTheme.glassBorder,
                                  backgroundImage: NetworkImage(av['url']!),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      CyberTextField(
                        controller: urlController,
                        labelText: 'CUSTOM AVATAR IMAGE URL',
                        prefixIcon: Icons.link,
                        onChanged: (val) {
                          setModalState(() {
                            selectedAvatarUrl = val.trim();
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      CyberTextField(
                        controller: nameController,
                        labelText: 'FULL NAME',
                        prefixIcon: Icons.badge_outlined,
                        validator: (val) => val!.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      CyberTextField(
                        controller: tagController,
                        labelText: 'GAMER TAG',
                        prefixIcon: Icons.sports_esports_outlined,
                        validator: ValidationUtils.validateUsername,
                      ),
                      const SizedBox(height: 16),

                      // Gender Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: selectedGender,
                        dropdownColor: AppTheme.darkBackground,
                        decoration: InputDecoration(
                          labelText: 'GENDER',
                          labelStyle: const TextStyle(color: Colors.white60),
                          prefixIcon: const Icon(
                            Icons.people_outline,
                            color: AppTheme.cyanBlue,
                          ),
                          filled: true,
                          fillColor: AppTheme.glassBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppTheme.glassBorder,
                            ),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        items: ['Male', 'Female', 'Non-binary', 'Unknown'].map((
                          String value,
                        ) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setModalState(() {
                            selectedGender = val!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Date of Birth DatePicker trigger
                      InkWell(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: dob ?? DateTime(2000),
                            firstDate: DateTime(1900),
                            lastDate: DateTime.now(),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.dark(
                                    primary: AppTheme.neonPurple,
                                    onPrimary: Colors.white,
                                    surface: AppTheme.darkBackground,
                                    onSurface: Colors.white,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setModalState(() {
                              dob = picked;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'DATE OF BIRTH',
                            labelStyle: const TextStyle(color: Colors.white60),
                            prefixIcon: const Icon(
                              Icons.calendar_today,
                              color: AppTheme.cyanBlue,
                            ),
                            filled: true,
                            fillColor: AppTheme.glassBackground,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: AppTheme.glassBorder,
                              ),
                            ),
                          ),
                          child: Text(
                            dob == null
                                ? 'SELECT DATE'
                                : '${dob!.year}-${dob!.month.toString().padLeft(2, '0')}-${dob!.day.toString().padLeft(2, '0')}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      CyberTextField(
                        controller: nationController,
                        labelText: 'NATIONALITY',
                        prefixIcon: Icons.flag_outlined,
                        validator: (val) => val!.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),

                      // Favorite Game Dropdown
                      DropdownButtonFormField<String>(
                        initialValue: favoriteGame,
                        dropdownColor: AppTheme.darkBackground,
                        decoration: InputDecoration(
                          labelText: 'FAVORITE SIMULATION',
                          labelStyle: const TextStyle(color: Colors.white60),
                          prefixIcon: const Icon(
                            Icons.sports_esports,
                            color: AppTheme.cyanBlue,
                          ),
                          filled: true,
                          fillColor: AppTheme.glassBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppTheme.glassBorder,
                            ),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        items: [
                          'Tic Tac Toe',
                          'Snake Game',
                          'Rock Paper Scissors',
                          'Quiz Game',
                          'Flappy Cyber',
                          'Neon Pong',
                          'Memory Match',
                          '2048 Matrix',
                          'Checkers',
                          'Endless Highway Racing',
                          'Traffic Dodger',
                          'Space Shooter',
                          'Endless Runner',
                          'Node Slicer'
                        ].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setModalState(() {
                            favoriteGame = val!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      CyberTextField(
                        controller: bioController,
                        labelText: 'NEURAL MEMORANDUM (BIO)',
                        prefixIcon: Icons.edit_note,
                      ),
                      const SizedBox(height: 24),

                      CyberButton(
                        text: 'PERSIST IDENTITY DATA',
                        icon: Icons.save,
                        onPressed: () {
                          if (_editFormKey.currentState!.validate()) {
                            ref.read(userProfileProvider.notifier).updateFullProfile(
                              fullName: nameController.text.trim(),
                              username: tagController.text.trim(),
                              gender: selectedGender,
                              nationality: nationController.text.trim(),
                              dateOfBirth: dob ?? DateTime(2000, 1, 1),
                              bio: bioController.text.trim(),
                              favoriteGame: favoriteGame,
                              avatarUrl: selectedAvatarUrl.trim(),
                            );
                            Navigator.pop(context);
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
