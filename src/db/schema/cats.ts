import { pgTable, uuid, varchar, integer, timestamp } from 'drizzle-orm/pg-core';

export const cats = pgTable('cats', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').notNull(),
  name: varchar('name', { length: 50 }).notNull(),
  hunger: integer('hunger').default(100).notNull(),
  happiness: integer('happiness').default(100).notNull(),
  affection: integer('affection').default(50).notNull(),
  energy: integer('energy').default(100).notNull(),
  level: integer('level').default(1).notNull(),
  exp: integer('exp').default(0).notNull(),
  coins: integer('coins').default(0).notNull(),
  hearts: integer('hearts').default(0).notNull(),
  lastActiveAt: timestamp('last_active_at', { withTimezone: true }).defaultNow().notNull(),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull()
});

export const catActions = pgTable('cat_actions', {
  id: uuid('id').primaryKey().defaultRandom(),
  catId: uuid('cat_id').notNull().references(() => cats.id, { onDelete: 'cascade' }),
  actionType: varchar('action_type', { length: 20 }).notNull(),
  itemId: uuid('item_id'),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow().notNull()
});
