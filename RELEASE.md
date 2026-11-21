# Curio Android release

Package: `com.krishiv.curio`. This build: `1.1.0+4`.
Support: **krishivkedia@gmail.com**.

## Backend setup

In the hosted Supabase project's SQL Editor, run the entire
[`supabase/setup.sql`](supabase/setup.sql) file. It handles fresh and partial
setups, preserves existing progress, and can be run again. Do not install the
app by running a later migration on its own or by running demo-data scripts.
For a CLI-managed project, use its ordered migrations instead.

Save the three HTML files in `supabase/templates/` into the hosted project's
Confirm signup, Magic Link and Reset Password templates. Each uses `{{ .Token }}`.
Curio accepts 6–10 digits and waits for an explicit submit. The build's
`OTP_LENGTH` controls the initial appearance only. Enable email confirmation and
configure SMTP for delivery to real parents. Local `supabase/config.toml` does
not change a hosted project's email settings.

Add `io.curio.app://login-callback/` to the allowed authentication redirects.
Deploy the `delete-account` and `parent-digest` edge functions using the project
configuration and secrets described in [`SUPABASE_SETUP.md`](SUPABASE_SETUP.md).
The hourly family schedule is optional if reminders and weekly emails are off.

## Signing and build

This is an existing Play Store release: reuse its original upload key. Match
the certificate to **Play Console → App integrity → Upload key certificate**.
`android/key.properties` is local and ignored by git. Set its `storeFile` to
the original keystore's actual path; do not substitute another app's keystore
or the Android debug keystore. The previous version's upload key remains the
authority even if an unrelated local bundle was signed differently.

The previous `1.0.0+3` signing record used `~/Downloads/upload-keystore.jks`.
Its public certificate is `build/release/curio-upload-certificate.pem`. The
build checksum and signing record are in `build/release/release-info.json`.

Upload certificate SHA-256:

```text
7D:98:E4:89:44:06:4D:3C:7F:59:B4:E4:9D:38:EB:4E:99:76:EE:E4:ED:47:F3:9D:9A:FB:C3:A2:C3:0F:F7:18
```

Verify the signed bundle's certificate fingerprint against the **Upload key
certificate** in Play Console. Use the upload fingerprint listed under App
integrity. [Android signing documentation](https://developer.android.com/studio/publish/app-signing)
The previous local bundle was preserved at
`build/release-reference/previous-app-release.aab` for reference.

```bash
python3 tool/release_check.py --platform android
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release
```

Upload `build/app/outputs/bundle/release/app-release.aab` to an internal testing
track first. The version code must exceed the latest version in Play Console.
Adjust the build number in `pubspec.yaml` if Play Console already has a higher one.

Publish the files in `docs/` on your public support site and use the hosted
`privacy.html` and `delete-account.html` URLs in the listing. The support address
has been filled in; the public hosting URL is chosen in Play Console.

## Hosted acceptance check

Before production, verify this against the actual connected project and an
Android internal-test installation:

1. A parent signs up, receives the code, submits every digit and completes setup.
2. Sign-out, password sign-in, email-code sign-in and password recovery work.
3. Home shows a featured challenge and one game each in Maths, Logic, Thinking,
   Memory and English. The Games tab shows the same six daily picks.
4. Complete each game, reopen it, and confirm XP is awarded once. Restart the
   app and verify saved XP, discoveries and badges remain.
5. Complete a game offline, restart, reconnect and verify it syncs once.
6. Account export and account deletion work through the deployed backend.
7. A verified family opts into weekly reports and receives the next completed
   week's report in the app and in their email inbox.

Local tests and builds cannot verify hosted email delivery, hosted function
deployment or Play Console's current upload certificate. These checks require
the connected project and original upload key.
