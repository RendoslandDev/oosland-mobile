# osland.

Social fashion campaign app for stylists, models, designers, and gifters. Compete for best dressed with two-phase submissions: a clothes photo and a walking video.

## Features

- **Home feed** — vertical posts with Phase 1 (clothes) / Phase 2 (walk) media, likes, reposts
- **Campaign upload** — guided 2-step wizard (clothes photo → walk video → publish)
- **Folders** — save looks and inspiration
- **Gifting** — send virtual gifts from post detail
- **Profiles** — roles, tier badges (pre-celeb, celebrity)

## Getting started

### Demo mode (no Supabase required)

```bash
flutter pub get
flutter run
```

The app runs in **demo mode** when `SUPABASE_URL` and `SUPABASE_ANON_KEY` are not set. Tap **Sign in** on the login screen to explore with seeded sample data.

### Supabase mode

1. Create a [Supabase](https://supabase.com) project
2. Run migrations in order from `supabase/migrations/`
3. Run the app with your credentials:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

## Project structure

```
lib/
  core/           # theme, router, Supabase config
  features/       # auth, feed, folders, campaigns, profile
  shared/         # models, repositories, widgets
supabase/
  migrations/     # Postgres schema + RLS
```

## Two-phase submission

Every campaign post requires both:

1. **Phase 1** — still photo of the dress/garment
2. **Phase 2** — vertical video of the user walking in the outfit

Publish is disabled until both phases are complete.
# oosland-mobile
