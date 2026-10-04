import { eq, and } from 'drizzle-orm';
import { DrizzleDB } from '../../db/index.js';
import { cats, catActions } from '../../db/schema/cats.js';
import { RedisClient } from '../../plugins/redis.js';

export interface OfflineProgressResult {
  durationSeconds: number;
  rewards: { coins: number; exp: number };
  catStatusChanges: { hunger: number; happiness: number; energy: number };
  events: Array<{ type: string; value: number; message: string }>;
}

export class CatsService {
  private readonly MAX_OFFLINE_HOURS = 168;
  private readonly HUNGER_DECAY_PER_HOUR = 5;
  private readonly ENERGY_DECAY_PER_HOUR = 3;
  private readonly COINS_PER_HOUR = 10;

  constructor(
    private readonly db: DrizzleDB,
    private readonly redis: RedisClient
  ) {}

  async findByIdAndUser(catId: string, userId?: string) {
    const where = userId
      ? and(eq(cats.id, catId), eq(cats.userId, userId))
      : eq(cats.id, catId);

    const [cat] = await this.db.select().from(cats).where(where).limit(1);
    return cat;
  }

  async calculateOfflineRewards(
    cat: typeof cats.$inferSelect,
    lastActiveAt: Date
  ): Promise<OfflineProgressResult> {
    const now = new Date();
    const diffMs = now.getTime() - lastActiveAt.getTime();
    const durationSeconds = Math.floor(diffMs / 1000);
    const hoursAway = Math.min(
      Math.floor(durationSeconds / 3600),
      this.MAX_OFFLINE_HOURS
    );

    const hungerDecay = Math.min(
      hoursAway * this.HUNGER_DECAY_PER_HOUR,
      cat.hunger
    );
    const energyDecay = Math.min(
      hoursAway * this.ENERGY_DECAY_PER_HOUR,
      cat.energy
    );
    const coinsEarned = hoursAway * this.COINS_PER_HOUR;
    const expEarned = Math.floor(hoursAway * 5);

    const events = [];
    if (coinsEarned > 0) {
      events.push({
        type: 'coins',
        value: coinsEarned,
        message: `${hoursAway}시간 동안 ${coinsEarned} 코인을 모았어요`
      });
    }
    if (hungerDecay > 0) {
      events.push({
        type: 'hunger',
        value: -hungerDecay,
        message: '고양이가 배고파해요'
      });
    }

    return {
      durationSeconds,
      rewards: { coins: coinsEarned, exp: expEarned },
      catStatusChanges: {
        hunger: -hungerDecay,
        happiness: 0,
        energy: -energyDecay
      },
      events
    };
  }

  async applyOfflineChanges(
    catId: string,
    progress: OfflineProgressResult
  ) {
    await this.db
      .update(cats)
      .set({
        hunger: Math.max(
          0,
          cats.hunger + progress.catStatusChanges.hunger
        ),
        energy: Math.max(
          0,
          cats.energy + progress.catStatusChanges.energy
        ),
        coins: cats.coins + progress.rewards.coins,
        exp: cats.exp + progress.rewards.exp,
        lastActiveAt: new Date()
      })
      .where(eq(cats.id, catId));
  }

  async executeAction(
    cat: typeof cats.$inferSelect,
    type: 'feed' | 'play' | 'walk',
    itemId?: string
  ) {
    const updates: Partial<typeof cats.$inferInsert> = {};

    switch (type) {
      case 'feed':
        if (!itemId) {
          throw new Error('itemId required for feed action');
        }
        updates.hunger = Math.min(100, cat.hunger + 30);
        updates.happiness = Math.min(100, cat.happiness + 5);
        break;
      case 'play':
        if (cat.energy < 20) {
          throw new Error('INSUFFICIENT_ENERGY');
        }
        updates.happiness = Math.min(100, cat.happiness + 20);
        updates.energy = Math.max(0, cat.energy - 20);
        updates.affection = Math.min(100, cat.affection + 10);
        break;
      case 'walk':
        if (cat.energy < 30) {
          throw new Error('INSUFFICIENT_ENERGY');
        }
        updates.energy = Math.max(0, cat.energy - 30);
        updates.exp = cat.exp + 15;
        break;
    }

    await this.db.transaction(async (tx) => {
      await tx
        .update(cats)
        .set({ ...updates, lastActiveAt: new Date() })
        .where(eq(cats.id, cat.id));

      await tx.insert(catActions).values({
        catId: cat.id,
        actionType: type,
        itemId,
        createdAt: new Date()
      });
    });

    return {
      success: true,
      cat: {
        hunger: updates.hunger ?? cat.hunger,
        happiness: updates.happiness ?? cat.happiness,
        energy: updates.energy ?? cat.energy,
        affection: updates.affection ?? cat.affection
      },
      balance: {
        coins: cat.coins,
        hearts: cat.hearts
      }
    };
  }

  async getIdempotentResponse(key: string) {
    const cached = await this.redis.get(`idempotency:${key}`);
    return cached ? JSON.parse(cached) : null;
  }

  async cacheIdempotentResponse(
    key: string,
    response: any,
    ttlSeconds: number
  ) {
    await this.redis.setex(
      `idempotency:${key}`,
      ttlSeconds,
      JSON.stringify(response)
    );
  }
}
