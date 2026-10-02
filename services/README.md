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

Each folder has its own `Dockerfile`. Images promote **dev → qa → production** (tags `0.1-dev`, `0.1-qa`, `0.1`).
