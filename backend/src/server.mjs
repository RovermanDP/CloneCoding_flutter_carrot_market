import http from 'node:http';

import { database, databasePath } from './db.mjs';

const PORT = Number.parseInt(process.env.PORT ?? '4000', 10);
const DEFAULT_USER_ID = 'demo-user';

function sendJson(response, statusCode, payload) {
  response.writeHead(statusCode, {
    'Content-Type': 'application/json; charset=utf-8',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET,POST,DELETE,OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type,x-user-id',
  });
  response.end(JSON.stringify(payload, null, 2));
}

function sendNoContent(response) {
  response.writeHead(204, {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET,POST,DELETE,OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type,x-user-id',
  });
  response.end();
}

function getUserId(request) {
  const userId = request.headers['x-user-id'];
  return typeof userId === 'string' && userId.trim() ? userId.trim() : DEFAULT_USER_ID;
}

async function readJsonBody(request) {
  const chunks = [];

  for await (const chunk of request) {
    chunks.push(chunk);
  }

  if (chunks.length === 0) {
    return {};
  }

  return JSON.parse(Buffer.concat(chunks).toString('utf8'));
}

function toListingSummary(row) {
  return {
    id: row.id,
    regionId: row.region_id,
    title: row.title,
    location: row.location,
    price: row.price,
    likes: row.likes,
    imageUrl: row.image_url,
    isFavorite: Boolean(row.is_favorite),
    seller: {
      id: row.seller_id,
      name: row.seller_name,
      regionName: row.seller_region_name,
      mannerTemp: row.seller_manner_temp,
    },
  };
}

const selectListingRows = `
  SELECT
    l.id,
    l.region_id,
    l.seller_id,
    l.title,
    l.description,
    l.location,
    l.price,
    l.likes,
    l.image_url,
    l.posted_hours_ago,
    l.views,
    l.chat_count,
    l.interest_count,
    l.negotiable,
    u.name AS seller_name,
    r.name AS seller_region_name,
    u.manner_temp AS seller_manner_temp,
    u.profile_image_url AS seller_profile_image_url,
    EXISTS (
      SELECT 1
      FROM favorites f
      WHERE f.user_id = ? AND f.listing_id = l.id
    ) AS is_favorite
  FROM listings l
  JOIN users u ON u.id = l.seller_id
  JOIN regions r ON r.id = u.region_id
`;

function listListings(userId, regionId, query) {
  let sql = selectListingRows;
  const params = [userId];
  const conditions = [];

  if (regionId) {
    conditions.push('l.region_id = ?');
    params.push(regionId);
  }

  if (query) {
    conditions.push('(LOWER(l.title) LIKE ? OR LOWER(l.description) LIKE ?)');
    params.push(`%${query}%`, `%${query}%`);
  }

  if (conditions.length > 0) {
    sql += ` WHERE ${conditions.join(' AND ')}`;
  }

  sql += ' ORDER BY CAST(l.id AS INTEGER)';

  return database.prepare(sql).all(...params).map(toListingSummary);
}

function getListingDetail(userId, listingId) {
  const row = database
    .prepare(`${selectListingRows} WHERE l.id = ?`)
    .get(userId, listingId);

  if (!row) {
    return null;
  }

  const relatedRows = database
    .prepare(
      `${selectListingRows}
       WHERE l.seller_id = ? AND l.id != ?
       ORDER BY CAST(l.id AS INTEGER)
       LIMIT 4`,
    )
    .all(userId, row.seller_id, row.id)
    .map(toListingSummary);

  return {
    ...toListingSummary(row),
    description: row.description,
    postedHoursAgo: row.posted_hours_ago,
    views: row.views,
    chatCount: row.chat_count,
    interestCount: row.interest_count,
    negotiable: Boolean(row.negotiable),
    seller: {
      id: row.seller_id,
      name: row.seller_name,
      regionId: row.region_id,
      regionName: row.seller_region_name,
      mannerTemp: row.seller_manner_temp,
      profileImageUrl: row.seller_profile_image_url,
    },
    relatedListings: relatedRows,
  };
}

function listFavorites(userId) {
  const rows = database
    .prepare(
      `${selectListingRows}
       JOIN favorites f2 ON f2.listing_id = l.id
       WHERE f2.user_id = ?
       ORDER BY f2.created_at DESC`,
    )
    .all(userId, userId);

  return rows.map(toListingSummary);
}

function ensureUser(userId) {
  const existing = database
    .prepare('SELECT id FROM users WHERE id = ?')
    .get(userId);

  if (existing) {
    return;
  }

  database
    .prepare(
      `INSERT INTO users (
        id, name, region_id, manner_temp, profile_image_url, is_seller
      ) VALUES (?, ?, ?, ?, ?, 0)`,
    )
    .run(userId, userId, 'ara', 36.5, 'assets/images/user.png');
}

function routeNotFound(response) {
  sendJson(response, 404, {
    message: 'Route not found.',
  });
}

const server = http.createServer(async (request, response) => {
  const method = request.method ?? 'GET';
  const url = new URL(request.url ?? '/', `http://${request.headers.host ?? 'localhost'}`);
  const pathname = url.pathname;

  try {
    if (method === 'OPTIONS') {
      sendNoContent(response);
      return;
    }

    if (method === 'GET' && pathname === '/health') {
      sendJson(response, 200, {
        status: 'ok',
        service: 'flutter-carrot-market-backend',
        dbPath: databasePath,
        now: new Date().toISOString(),
      });
      return;
    }

    if (method === 'GET' && pathname === '/api/regions') {
      const rows = database
        .prepare('SELECT id, name FROM regions ORDER BY id')
        .all();

      sendJson(response, 200, {
        regions: rows,
      });
      return;
    }

    if (method === 'GET' && pathname === '/api/listings') {
      const userId = getUserId(request);
      const region = url.searchParams.get('region');
      const query = url.searchParams.get('query')?.trim().toLowerCase() ?? '';
      const items = listListings(userId, region, query);

      sendJson(response, 200, {
        items,
        count: items.length,
      });
      return;
    }

    if (method === 'GET' && pathname.startsWith('/api/listings/')) {
      const userId = getUserId(request);
      const listingId = pathname.split('/').at(-1);
      const item = listingId ? getListingDetail(userId, listingId) : null;

      if (!item) {
        sendJson(response, 404, {
          message: 'Listing not found.',
        });
        return;
      }

      sendJson(response, 200, { item });
      return;
    }

    if (method === 'GET' && pathname === '/api/favorites') {
      const userId = getUserId(request);
      ensureUser(userId);

      sendJson(response, 200, {
        userId,
        items: listFavorites(userId),
      });
      return;
    }

    if (method === 'POST' && pathname === '/api/favorites') {
      const userId = getUserId(request);
      ensureUser(userId);

      const body = await readJsonBody(request);
      const listingId = typeof body.listingId === 'string' ? body.listingId : '';
      const listing = database
        .prepare('SELECT id FROM listings WHERE id = ?')
        .get(listingId);

      if (!listing) {
        sendJson(response, 404, {
          message: 'Listing not found.',
        });
        return;
      }

      database
        .prepare(
          'INSERT OR IGNORE INTO favorites (user_id, listing_id) VALUES (?, ?)',
        )
        .run(userId, listingId);

      sendJson(response, 201, {
        userId,
        item: getListingDetail(userId, listingId),
      });
      return;
    }

    if (method === 'DELETE' && pathname.startsWith('/api/favorites/')) {
      const userId = getUserId(request);
      ensureUser(userId);

      const listingId = pathname.split('/').at(-1);
      database
        .prepare('DELETE FROM favorites WHERE user_id = ? AND listing_id = ?')
        .run(userId, listingId);

      sendNoContent(response);
      return;
    }

    routeNotFound(response);
  } catch (error) {
    sendJson(response, 500, {
      message: 'Internal server error.',
      error: error instanceof Error ? error.message : String(error),
    });
  }
});

server.listen(PORT, () => {
  console.log(`Backend listening on http://localhost:${PORT}`);
  console.log(`SQLite database: ${databasePath}`);
});
