# Backend

SQLite-backed local backend for the current Flutter frontend.

## Run

```bash
node src/server.mjs
```

Or from this folder:

```bash
npm run start
```

## Default URL

`http://localhost:4000`

## Endpoints

- `GET /health`
- `GET /api/regions`
- `GET /api/listings`
- `GET /api/listings/:id`
- `GET /api/favorites`
- `POST /api/favorites`
- `DELETE /api/favorites/:listingId`

## Notes

- The SQLite database file is created at `backend/data/carrot-market.sqlite`.
- The database is seeded from the existing mock data on first run.
- The backend uses `x-user-id` when provided. If omitted, it defaults to `demo-user`.
- CORS is enabled for local Flutter web development.
