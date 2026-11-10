# UsTwo — connected couple app (PWA)

This version includes the real-time Supabase integration points and database setup script.

## What is included
- Premium, mobile-first couple app interface
- Anonymous sign-in (no email/password needed in this starter)
- Create a room and join from the second phone using an invite code
- Real-time chat and online presence
- Private photo memories in Supabase Storage
- Voice-note upload and playback
- Daily answers saved to the shared room
- Mini-game prompts
- Manual location sharing (only after the user taps Share)
- PWA manifest + service worker so it can be added to Android home screen

## Important before using with real personal data
You must configure your own Supabase backend. The app cannot sync between two phones until this is done. A free Supabase project is sufficient for a small test, subject to Supabase's current limits.

### 1. Create Supabase project
Go to https://supabase.com and create a project. In Authentication settings, enable **Anonymous Sign-Ins**.

### 2. Run database setup
Open SQL Editor → New query, paste all contents of `supabase_setup.sql`, and run it. The script creates the tables, room functions, access policies and private storage bucket.

### 3. Get API details
Project Settings → API. Copy:
- Project URL
- anon / publishable key (NOT service_role)

Open the app → Settings → paste both → Connect backend.

### 4. Pair the two phones
- Person 1 enters their name and creates a room code.
- Share that code privately with Person 2.
- Person 2 opens the same app, enters their name and that code, then taps Join room.
- Both can now use the same room.

Each phone gets its own anonymous account. Do not clear browser/app data after pairing, or the anonymous account identity may be lost. For production, replace anonymous auth with a stronger account/recovery flow.

## Free hosting / Android install
1. Extract this ZIP.
2. Upload the folder contents to https://app.netlify.com/drop (free static hosting is enough).
3. Open the deployed HTTPS link in Chrome on each Android phone.
4. Chrome menu → Add to Home screen / Install app.

## Security notes
- Do not put the Supabase `service_role` secret in the app.
- Keep the Storage bucket private.
- Room invite codes are private credentials: share only with the intended partner.
- Location is not tracked in the background; a Google Maps link is sent only after explicit tap and permission.
- This is a functional starter, not a security-audited commercial product. Anonymous sign-in means users should protect their device/browser data. For a public launch, add stronger authentication, invite-code rate limiting, abuse controls and a security review.
