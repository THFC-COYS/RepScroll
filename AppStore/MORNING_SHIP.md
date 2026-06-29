# RepScroll — ship this morning

**Target:** TestFlight tonight → App Store review submit by noon.

## Before you archive (15 min)

0. **Build fails?** Run `./scripts/fix-xcode-simulator.sh` then pick **iPhone 17 Pro** simulator (or a physical iPhone).
1. **Apple Developer account** signed in (Xcode → Settings → Accounts).
2. **Create App ID** `com.repscroll.app` + App Group `group.com.repscroll.shared`.
3. **Enable GitHub Pages** on repo → Settings → Pages → source: `main` / folder: `/docs`  
   Privacy: https://thfc-coys.github.io/RepScroll/privacy.html  
   Terms: https://thfc-coys.github.io/RepScroll/terms.html
4. **App Store Connect** → New App:
   - Name: RepScroll
   - Bundle ID: com.repscroll.app
   - SKU: repscroll-ios
   - Primary: Health & Fitness
5. **Subscriptions** (must match `Products.storekit`):
   - Group: RepScroll Premium
   - `com.repscroll.premium.monthly` — $6.99, 1 week free trial
   - `com.repscroll.premium.yearly` — $49.00
6. **Metadata** — copy from `AppStore/metadata.json` into ASC fields.
   - What's New: `AppStore/whats-new.txt`
   - Privacy answers: `AppStore/privacy-nutrition.json`
   - Age rating: `AppStore/age-rating.json`
   - Subscriptions: `AppStore/subscriptions-asc.json`
7. **Screenshots** — placeholder frames in `AppStore/screenshots/` (run `python3 scripts/generate_screenshot_frames.py`). Replace with real device captures before submit: Home, Challenge, Gate, History, Paywall (6.7" + 6.5").
8. **Age rating** — 4+, no mature content. Encryption: No (already in Info.plist).
9. **Preflight** — `DEVELOPMENT_TEAM=XXX ./scripts/preflight.sh` before archive.

## Archive & upload

```bash
cd /Users/greg/RepScroll
export DEVELOPMENT_TEAM="YOUR_10_CHAR_TEAM_ID"
./scripts/ship.sh
```

Or in Xcode: **Product → Archive** → Distribute → App Store Connect → Upload.

Paste `AppStore/REVIEW_NOTES.txt` into App Review Information → Notes.

## Physical device smoke test (required)

Vision rep counting needs a real iPhone camera. Simulator cannot validate the core loop.

- [ ] Onboarding completes
- [ ] Gate flow: 10 push-ups → unlock timer starts
- [ ] Challenge saves session → streak updates
- [ ] Widget shows streak after a session
- [ ] Paywall loads products (sandbox Apple ID)
- [ ] Restore purchases works

## Common rejection fixes

| Issue | Fix |
|-------|-----|
| Missing subscription links | Paywall has Privacy + Terms links |
| Misleading "free trial" on yearly | Button says "Subscribe yearly" for yearly plan |
| Screen Time claim | Review notes + Terms say v1.0 is simulation |
| Camera crash | Test on device, grant camera permission |

## After TestFlight

Add internal testers → exercise the gate loop once → Submit for Review.