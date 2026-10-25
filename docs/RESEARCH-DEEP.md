# أمان الغرفة — Deep GitHub/Web research (pre-build)

## Key open-source / reverse-engineering sources
| Repo / page | URL | What we adopt |
|---|---|---|
| SignalScout (iOS) | https://github.com/ridpath/SignalScout | Tracker signature JSON shape; magnetometer rolling baseline (~20 µT above baseline @ 20 Hz); reflection grid + torch; honest iOS limits. **BSL 1.1 — learn algorithms, write our own code, do not copy.** |
| AirGuard-iOS (SEEMOO) | https://github.com/seemoo-lab/AirGuard-iOS | Persistence idea (≥3 sightings + location change for stalking). For room-check we use **hot/cold RSSI** instead of long-term stalking. |
| VIGIL | https://github.com/KaraZajac/VIGIL | Exact BLE wire formats for AirTag/Find My, Tile, SmartTag, Google FMDN, DULT. |
| furiousMAC/continuity Find My | https://github.com/furiousMAC/continuity/blob/master/messages/findmy.md | OF adv: company `0x004C`, type `0x12`, len `0x19`, status, pubkey… |
| findphone Tracker.swift | https://github.com/ben-z/findphone | Apple Continuity type parsing from manufacturer data. |
| IntervalMedia/SignalTrail | https://github.com/IntervalMedia/SignalTrail | AllowDuplicates scan, company ID alerts, Flipper/HC-05 seeds. |
| pwnsy Lens Finder | https://pwnsy.com/tools/antispy/lens-finder/ | Glint scoring: threshold 232–250, cluster 2–80 px, fill≥45%, persistence, steadiness, roundness. |
| MagnetometerDemo / MagnetoMeter | github.com/mryssng/MagnetometerDemo, foundry/MagnetoMeter | Prefer **raw CMMagnetometer** or CLHeading xyz for *local* fields; calibrated CMDeviceMotion rejects local spikes. |
| USENIX “Sneaky Spy Devices…” | usenix.org/.../sneaky-spy-devices-and-defective-detectors | Magnetometer apps are crude metal detectors; **must not claim RF/camera detection**. Validates «فحص مساعد». |
| wall-scanner-metal-detector | https://github.com/Lapnito/wall-scanner-metal-detector | Stud-finder style: rolling baseline, ~6–25 µT delta thresholds. |

## Concrete BLE signatures to ship (bundled + remote catalog)
| Family | Match |
|---|---|
| Apple Find My / AirTag | mfg company ID LE `4C 00`, Continuity type `0x12` (also service FD6F/FD9F heuristics) |
| Tile | service data / UUID `FEED`, `FEEC`, `FE84` |
| Samsung SmartTag | service `FD5A` / `FDDF` |
| Google Find My Device | service `FEAA`, frame `0x40`/`0x41` |
| DULT (emerging) | service `FCB2` |
| Chipolo / Pebblebee | FE95 / FE9F heuristics |
| DIY risk | ESP32/nRF name/prefix heuristics only as “مجهول يستاهل نظرة” |

**iOS limits:** no BLE MAC → use `CBPeripheral.identifier` + adv payload. AllowDuplicates=true while foreground. RSSI for hot/cold only (poor absolute distance).

## Magnetometer algorithm (adopt)
1. Sample raw magnetometer @ 20 Hz (`CMMotionManager.magnetometerUpdateInterval = 0.05`).
2. Magnitude `√(x²+y²+z²)`.
3. Warm-up 1.5 s → rolling baseline = mean of last 40 samples (2 s).
4. Spike if `|mag − baseline| ≥ spikeDelta` for ≥3 consecutive samples.
5. Defaults: `spikeDelta = 18 µT` (Quick), `12 µT` (Thorough); hysteresis clear at `delta < 8 µT`.
6. Pin spike with haptic; never label as “camera”.
7. Show live µT + chart + baseline line.

## Lens-glint algorithm (adopt from pwnsy, native AVFoundation)
1. Rear camera + torch ON; optional contrast boost.
2. Downscale frame ~160–320 px wide; luminance threshold (default 244/255).
3. 4-neighbour clusters; keep size 2–80 px, max side ≤14, fill ≥0.45.
4. Track spots across frames (match within ~4.5% frame width); score persistence + steadiness + roundness.
5. User marks “اشتباه” — app never auto-claims camera found.
6. All frames on-device; never upload.

## Features we WILL ship (improved list)
1. Scan modes Quick 30s / Balanced / Thorough (from catalog thresholds).
2. Magnetometer needle + radar + baseline + spike pins + haptics.
3. BLE radar with signature DB (AirTag/Tile/SmartTag/Google/DULT) + unknown persistent + RSSI bars + hot/cold for one selected device.
4. Lens glint camera + torch + auto-highlight candidates + manual mark.
5. Room checklists: شاليه / فندق / غرفة قياس / استراحة (remote catalog).
6. Multi-signal result card «الغرفة صافية» / «فيه نقاط تستاهل نظرة» + share image.
7. Everywhere: **فحص مساعد — ما يستبدل معدات احترافية**.
8. Offline-first + GitHub Pages `catalog.json` for checklists/tips/thresholds/text.
9. Arabic + English RTL; design B شاليه; door icon.

## Features we will NOT claim
- Guaranteed hidden-camera detection
- True IR night vision
- Full LAN ARP / Wi‑Fi client list (no wifi-info entitlement chase in v1)
- Kicking devices off Wi‑Fi
- Magnetometer = RF detector
- Continuous background stalking alerts (v1 is room-check only)

## Legal / license note
SignalScout is BSL — **reimplement**, do not vendor their source. AirGuard/VIGIL/continuity docs are reference for wire formats (public RE).
