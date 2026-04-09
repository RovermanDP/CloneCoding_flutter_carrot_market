import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { DatabaseSync } from 'node:sqlite';

import {
  initialFavoritesByUser,
  listings,
  regions,
  users,
} from './data/seed.mjs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const dataDirectory = path.resolve(__dirname, '../data');
const databasePath = path.join(dataDirectory, 'carrot-market.sqlite');

fs.mkdirSync(dataDirectory, { recursive: true });

const database = new DatabaseSync(databasePath);
database.exec('PRAGMA foreign_keys = ON;');

function createSchema() {
  database.exec(`
    CREATE TABLE IF NOT EXISTS regions (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      region_id TEXT NOT NULL,
      manner_temp REAL NOT NULL,
      profile_image_url TEXT NOT NULL,
      is_seller INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (region_id) REFERENCES regions(id)
    );

    CREATE TABLE IF NOT EXISTS listings (
      id TEXT PRIMARY KEY,
      region_id TEXT NOT NULL,
      seller_id TEXT NOT NULL,
      title TEXT NOT NULL,
      description TEXT NOT NULL,
      location TEXT NOT NULL,
      price TEXT NOT NULL,
      likes INTEGER NOT NULL DEFAULT 0,
      image_url TEXT NOT NULL,
      posted_hours_ago INTEGER NOT NULL DEFAULT 0,
      views INTEGER NOT NULL DEFAULT 0,
      chat_count INTEGER NOT NULL DEFAULT 0,
      interest_count INTEGER NOT NULL DEFAULT 0,
      negotiable INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (region_id) REFERENCES regions(id),
      FOREIGN KEY (seller_id) REFERENCES users(id)
    );

    CREATE TABLE IF NOT EXISTS favorites (
      user_id TEXT NOT NULL,
      listing_id TEXT NOT NULL,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      PRIMARY KEY (user_id, listing_id),
      FOREIGN KEY (user_id) REFERENCES users(id),
      FOREIGN KEY (listing_id) REFERENCES listings(id)
    );
  `);
}

function seedTableCounts() {
  return {
    regions: database.prepare('SELECT COUNT(*) AS count FROM regions').get().count,
    users: database.prepare('SELECT COUNT(*) AS count FROM users').get().count,
    listings: database.prepare('SELECT COUNT(*) AS count FROM listings').get().count,
    favorites: database.prepare('SELECT COUNT(*) AS count FROM favorites').get().count,
  };
}

function seedDatabase() {
  const counts = seedTableCounts();

  if (counts.regions === 0) {
    const insertRegion = database.prepare(
      'INSERT INTO regions (id, name) VALUES (?, ?)',
    );
    for (const region of regions) {
      insertRegion.run(region.id, region.name);
    }
  }

  if (counts.users === 0) {
    const insertUser = database.prepare(`
      INSERT INTO users (
        id, name, region_id, manner_temp, profile_image_url, is_seller
      ) VALUES (?, ?, ?, ?, ?, ?)
    `);

    for (const user of users) {
      insertUser.run(
        user.id,
        user.name,
        user.regionId,
        user.mannerTemp,
        user.profileImageUrl,
        user.isSeller ? 1 : 0,
      );
    }
  }

  if (counts.listings === 0) {
    const insertListing = database.prepare(`
      INSERT INTO listings (
        id, region_id, seller_id, title, description, location, price,
        likes, image_url, posted_hours_ago, views, chat_count,
        interest_count, negotiable
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    `);

    for (const listing of listings) {
      insertListing.run(
        listing.id,
        listing.regionId,
        listing.sellerId,
        listing.title,
        listing.description,
        listing.location,
        listing.price,
        listing.likes,
        listing.imageUrl,
        listing.postedHoursAgo,
        listing.views,
        listing.chatCount,
        listing.interestCount,
        listing.negotiable ? 1 : 0,
      );
    }
  }

  if (counts.favorites === 0) {
    const insertFavorite = database.prepare(
      'INSERT INTO favorites (user_id, listing_id) VALUES (?, ?)',
    );

    for (const [userId, listingIds] of Object.entries(initialFavoritesByUser)) {
      for (const listingId of listingIds) {
        insertFavorite.run(userId, listingId);
      }
    }
  }
}

createSchema();
seedDatabase();

export { database, databasePath };
