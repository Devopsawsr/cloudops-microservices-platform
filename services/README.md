# Service catalog

| Service | Type | Routes |
|---|---|---|
| gateway | edge | `/` `/api/*` |
| web | UI | pages + certificates |
| auth | API | `/api/signup` `/api/login` |
| catalog | API | `/api/books` |
| cart | API | `/api/cart` |
| orders | API | `/api/buy` `/api/orders` |
| learning | API | `/api/exam` `/api/exams` |
| labs | API | `/api/labs` |
| community | API | `/api/community` |
| certificates | API | `/api/certificates` |
| leaderboard | API | `/api/leaderboard` |

Each folder has its own `Dockerfile`. Our target release chain is **Dev → QA → Staging → Production**. Build a changed service once, test and scan it, then promote the same immutable image digest. Environment-dependent tags in current overlays are placeholders for future CI/CD, not evidence of existing artifact promotion.
