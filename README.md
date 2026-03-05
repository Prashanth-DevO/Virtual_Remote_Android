# Linux Joystick Client (Flutter)

Mobile controller app that discovers a Linux joystick server on local network and sends real-time UDP control packets.

## Demo Photos

Add your screenshots to `docs/demo/` with these names:

- `01-server-terminal.png`
- `02-discovery-screen.png`
- `03-character-mode.png`
- `04-vehicle-mode.png`

Then this README will render them automatically:

![Server Terminal](docs/demo/01-server-terminal.png)
![Discovery Screen](docs/demo/02-discovery-screen.png)
![Character Mode](docs/demo/03-character-mode.png)
![Vehicle Mode](docs/demo/04-vehicle-mode.png)

## Quick Start (Your 4 Steps)

1. Connect phone and Linux PC to the same Wi-Fi.
2. On Linux PC, run `ip -br a` and note active Wi-Fi IP (example: `10.15.31.96`).
3. Open the app on phone.
4. In **Find Servers**, scan and select the detected server.

## Linux Server Setup

On Linux host:

```bash
ip -br a
sudo chmod 666 /dev/uinput
./linux-joystick/build/virtual_remote_server
```

Expected startup output is similar to:

- `UDP control : 9000`
- `UDP discovery : 9002`
- `[lock] locking to ip=...`

## App Flow

1. Open app -> **Find Servers** screen.
2. Tap **Scan** (LAN broadcast discovery).
3. If LAN scan is blocked (hotspot/restricted network), type IP in **Manual IP** and scan again.
4. Tap a server tile (`Available` or `Locked`) to open controller UI.
5. Use:
- **Character mode**: dual analog sticks, D-pad, ABXY, LB/RB, LT/RT, Back/Start/Home.
- **Vehicle mode**: steering arrows + LT/RT pedals + core buttons.

## Verified Feature Checklist

Verified against project source:

- `Discovery over UDP port 9002`: implemented (`DiscoveryProtocol.discoveryPort = 9002`).
- `Control streaming to server port`: implemented (selected server `controlPort`, default expected `9000` on server).
- `Manual IP fallback`: implemented in discovery screen/controller.
- `Server lock status badge`: implemented (`Available` / `Locked` from flags bit).
- `Character + Vehicle controller layouts`: implemented.
- `Orientation lock in controller`: implemented (landscape in controller screen).
- `60Hz UDP control send loop`: implemented (`Timer.periodic(...16ms...)`).

## Build and Run

```bash
flutter pub get
flutter run
```

## Important Release Note

Currently `INTERNET` permission is present in:

- `android/app/src/debug/AndroidManifest.xml`
- `android/app/src/profile/AndroidManifest.xml`

For release APK/network use, also add it to:

- `android/app/src/main/AndroidManifest.xml`

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

## Troubleshooting

- No server found:
  - Confirm both devices are on same subnet.
  - Enter server IP manually in app and scan again.
  - Confirm server process is running and showing ports `9000/9002`.
- Controls not affecting game:
  - Ensure `/dev/uinput` permission is granted on Linux host.
  - Confirm the server is not locked to a different client IP.
