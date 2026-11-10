# UsTwo Android APK build project

Yeh **ready-to-build Android project** hai; yeh APK binary nahi hai. APK GitHub Actions se generate hoga.

## APK banane ka short process
1. ZIP extract karo.
2. GitHub par naya repository banao aur is folder ke saare files upload karo.
3. Repository me **Actions** tab kholo.
4. `Build UsTwo Android APK` workflow select karke **Run workflow** dabao.
5. Build complete hone par workflow run ke page ke neeche **Artifacts** me `UsTwo-debug-APK` milega.
6. Artifact download karke ZIP extract karo. `app-debug.apk` dono phones par install ki ja sakti hai. Android install prompt aaye toh browser/file manager ke liye “Install unknown apps” allow karna pad sakta hai.

## Dono phones connect karne ke liye
APK install hona aur dono phones ka aapas me sync hona alag cheezein hain. Shared chat/photos/presence chalane ke liye:
1. Ek free Supabase project banao.
2. Authentication me Anonymous Sign-Ins enable karo.
3. `www/supabase_setup.sql` ko Supabase SQL Editor me run karo.
4. Project URL aur anon/publishable key app ke Settings screen me dono phones par enter karo.
5. Ek phone room create kare; doosra same invite code se join kare.

**Important:** `service_role` key kabhi app me mat daalna. Sirf anon/publishable key use karna. Location sharing manual hai; background tracking nahi.

## Current limitation
- Is project se **debug APK** banti hai, Play Store release-signed APK nahi.
- APK ko compile karne ke liye GitHub account/repository aur internet chahiye. GitHub Actions free quota/limits ke adheen hai.
- Supabase setup ke bina dono phones ek doosre se connect nahi honge.
- Yeh starter build hai, security-audited commercial app nahi.
