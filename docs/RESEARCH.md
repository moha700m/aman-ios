# أمان الغرفة — Research (stock iOS, non-jailbreak)

## Competitors reviewed
- Hidden Camera Detector (Karachev) — lens filters + BLE radar + Wi‑Fi + magnetometer + room checklist + disclaimer
- Spyzero / hiddencameradetector.app — Wi‑Fi fingerprint + IR overlay + magnetometer baseline
- LensWise — 7-step guided check, 6 tools
- GitHub: SignalScout, SignalTrail — honest iOS BLE limits; AirTag/Tile signature matching; no Wi‑Fi client list

## Possible on stock iPhone
| Feature | API | Notes |
|---|---|---|
| Magnetometer µT live + chart + baseline | CoreMotion CMMagnetometer / CMDeviceMotion | Reuse تيّار; spikes ≠ proof (speakers, rebar, magnets) |
| BLE nearby scan + RSSI | CoreBluetooth | No MAC; randomized IDs |
| AirTag / Find My / Tile / SmartTag heuristics | Manufacturer data + service UUID signatures | High value; pattern DB like SignalScout |
| Camera + torch lens-glint assist | AVFoundation | User judges glint; AI optional later |
| Partial IR LED visibility | Same camera in dark | Weak — iPhone has IR cut filter; some bright IR LEDs visible, not true night-vision |
| Bonjour / local-network device hints | Network.framework + Local Network permission | Limited; NOT full Fing-style LAN ARP scan |
| Connected Wi‑Fi SSID/BSSID + OUI | NEHotspotNetwork / CNCopyCurrentNetworkInfo rules | Only current AP, not neighbor list |
| Guided room checklists | Local | Chalet / hotel / fitting room / Airbnb |
| Share result card (Snap/TikTok/X) | UIActivity / ImageRenderer | Viral loop |
| Widgets / Live Activity scan summary | WidgetKit | Optional v1.1 |
| On-device only, no photo upload | Privacy | App Store friendly |

## Not possible / must not claim
- Guaranteed detection of every hidden camera
- True IR night-vision camera mode
- Full Wi‑Fi client enumeration / port scan like desktop Fing
- ARP spoofing / kicking devices off Wi‑Fi (NetKill / NetCut) — jailbreak only
- Detect powered-off SD-only cameras via radio (magnetometer hint only, high FP)
- GPS tracker detection via magnetometer (unreliable)
- Continuous background BLE sweep as a product promise

## Positioning (Apple-safe)
Copy everywhere: **فحص مساعد** — لا يستبدل معدات احترافية. Overlap of 2–3 signals = “look closer,” never “camera found.”

## Strongest feature set to ship
1. Full guided flow: Quick 30s / Balanced / Thorough
2. Magnetometer with baseline + spike pin
3. BLE tracker radar (AirTag/Tile/SmartTag signatures + unknown persistent)
4. Lens glint camera + torch + contrast filter + mark pin
5. Room checklists (شاليه، فندق، غرفة قياس، استراحة)
6. Multi-signal score card + share sticker «الغرفة صافية»
7. Local-only privacy banner
8. Optional later: Bonjour hints, ultrasonic, widget

## Viral mechanics
- Hook: «افحص الشاليه قبل ما تجلس»
- Radar sweep + haptic on spike (game-feel)
- Share card for Snap/TikTok/X
- 30-second quick scan challenge
- Room-type templates people film
