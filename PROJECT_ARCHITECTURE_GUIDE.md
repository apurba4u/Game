# GameHub Developer & Architectural Guide 🚀
> **Welcome to the Grid, Operator!** ⚡
> Ei doc ta GameHub er full project architecture, structure, multiplayer features, ar shob games er working logic bujhte sahajjo korbe.

---

## 📁 1. Project Directory Structure
GameHub standard Feature-First architecture follow kore build kora hoyeche. Niche shob primary folders ar files er purpose explain kora holo:

| Directory Path | Purpose (Keno use kora hocche) | Key Elements |
| :--- | :--- | :--- |
| `lib/core/` | Global app utilities, theme configurations, validation and base routing engines. | `app_theme.dart`, `app_router.dart`, `base_game_controller.dart` |
| `lib/features/auth/` | Secure authentication system. Supabase database e sign up, login code verification manage kore. | `auth_provider.dart`, `signup_screen.dart`, `login_screen.dart` |
| `lib/features/dashboard/` | Core app console panel (System HUD) showing live user data, stats, and real-time leaderboard statistics. | `home_tab_screen.dart`, `stats_screen.dart`, `leaderboard_provider.dart` |
| `lib/features/profile/` | Cyber-identity customization grid. Streaks updates, banner theme updates, and local database sync. | `profile_screen.dart`, `profile_provider.dart` |
| `lib/features/games/` | Both turn-based P2P games and customized single-player CustomPainter game screens. | `space_shooter_screen.dart`, `checkers_screen.dart`, `pong_screen.dart` |

---

## 📡 2. Real-time Networking & Synchronization
GameHub e multi-player gaming system robust platform-agnostic dynamic sockets use kore build kora:

### UDP Broadcast & Multicast Auto-Discovery
* **Ki kaj kore:** Private WiFi connection e peer devices discover korte socket packets broad-broadcast ar multicast mode e run kora hoy.
* **Keno use kora hocche:** Player ra jeno manual router configurations chadao same wireless connection e automatic lobbies lists load korte pare.
* **Kivabe kaj kore:** 
  1. Room Host dynamic port select kore auto `9018` socket port open rakhe.
  2. Subscribed players UDP socket queries search path query scanner diye packet retrieve kore join list populate kore.

### Platform-Agnostic Web Signaling Fallback
* **Ki kaj kore:** Google Chrome or standard browser environments dynamic raw server socket configurations support kore na.
* **Kivabe kaj kore:** Browser build run time e logic track kore automated dynamic fallback handle kore **Supabase Realtime Broadcast Channels** e connect hoy, same P2P data packets format use kore sync path maintain kore.

### Host Authoritative Sync & Client-Side interpolation
* **Ki kaj kore:** Neon Pong ar multi-player physics collision lag-free 60 FPS update logic sync.
* **Kivabe kaj kore:** 
  - **Host** ball path updates ar dynamic physics boundaries evaluate kore exact vector calculation coordinate details share kore.
  - **Client** paddle position change packet transmit kore ar Host er update packet dynamic **linear interpolation (`lerpDouble`)** loop scan kore smoothly updates coordinate draw kore, zero jitter screen refresh deliver korar jonno.

---

## 🎮 3. Detailed Game Modules Explanations

### 1. Neon Checkers Strategy Board (`checkers_screen.dart`)
* **Game Logic:** Diagonal movement checkers board checks. AI modes automated min-max selection logic follow kore.
* **Collision Check:** Grid offsets touch bounds intersect check matrix tracking list check kore.
* **Score System:** Enemy checkers count, board clears tracking XP points generation hooks.

### 2. Highway Overdrive Perspective Racer (`highway_racing_screen.dart`)
* **Game Logic:** 3D pseudo-perspective perspective lane-shifting infinite racer game. CustomPainter continuous speed dynamic calculations.
* **Collision System:** Obstacle bounding boxes player car position overlapping checker.
* **Animation:** High frame-rate tick dynamic perspective line updates giving immediate high speed illusion.

### 3. Grid Traffic Dodger Vertical Racer (`traffic_dodger_screen.dart`)
* **Game Logic:** Vertical scrolling dodging obstacle game. Player finger horizontal motion tracking.
* **Score & Energy:** Battery items collect kore engine energy update path maintain kora.
* **Controls:** Direct finger swipe path delta coordinate values mapping listener.

### 4. Space Grid Shooter (`space_shooter_screen.dart`)
* **Game Logic:** Space shooter bullet projectile spawning, enemy formations, and collision check loops.
* **Animation:** Spark explosions particle fragments alpha updates, size decrements, and random angles rotation physics.
* **Controls:** Double joystick virtual path drag system.

### 5. Grid Matrix Platform Runner (`endless_runner_screen.dart`)
* **Game Logic:** Gravitational speed physics jumping and horizontal barrier hurdles slide mechanics.
* **Collision System:** Player floor tracking bounds checks obstacle overlaps trigger.
* **Controls:** Direct single tap triggers dynamic upward velocity leap.

### 6. Grid Node Slicer Touch Slicer (`node_slicer_screen.dart`)
* **Game Logic:** Swipe swipe finger node cuts. Green nodes slice trigger points, Red bombs slice trigger game over bounds.
* **Animation:** Smooth glowing particle trails mapping blade strokes.
* **Controls:** PanGesture recognizer coordinate offsets trace collector.

---

## 🔒 4. User Sign Up Credential Validator
* **Validation Logic:** User dynamic passwords metrics evaluates. Length check, symbols, digits, ar character classes scan.
* **UI indicators:** Continuous colored progress gauge strength value text changes (`WEAK PROTOCOL` 🔴, `MODERATE DECRYPTION` 🟡, `SECURE SYSTEM ENCRYPTED` 🟢) representation support system.
