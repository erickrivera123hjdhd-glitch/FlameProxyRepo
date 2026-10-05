# FlameProxy IPA builder

This repo builds a Theos tweak (adds an HTTP "Proxy" button) and injects it into your
BHTikTok+ IPA, producing an unsigned `app.ipa`.

## One-time setup: give the workflow your base IPA (pick ONE)
1. **Release (easiest, no URL needed):** Releases -> Draft a new release -> tag `base-ipa` ->
   attach your BHTikTok+ `.ipa` -> publish (a private repo keeps it private; limit 2 GB).
2. **Repository variable:** Settings -> Secrets and variables -> Actions -> Variables -> `IPA_URL` = direct download link.
3. **Run-time input:** Actions -> Build proxy IPA -> Run workflow -> fill `ipa_url`.
4. **Commit** the IPA as `ipa/app.ipa` (needs Git LFS if over 100 MB).

## Build
- Pushing changes to `Tweak.x`, `Makefile`, `control`, `FlameProxy.plist` or the workflow runs it automatically.
- Or: Actions -> Build proxy IPA -> Run workflow.

## Download
Open the finished run -> **Artifacts** at the bottom:
- `app-ipa-unsigned` -> zip containing `app.ipa` (sign/install with Sideloadly / AltStore)
- `FlameProxy-tweak` -> `FlameProxy.dylib` (+ `.deb` for jailbroken devices)

## Use
Tap the floating "Proxy" button, enter FlameProxies HTTP host/port/user/pass, Save & Enable,
then force-quit and reopen TikTok.

Note: untested. TikTok network stack may bypass the NSURLSession hook; verify your IP changes.
