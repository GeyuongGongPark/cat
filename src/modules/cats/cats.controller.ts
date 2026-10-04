import { FastifyRequest, FastifyReply } from 'fastify';
import { CatsService } from './cats.service.js';
import { NotFoundError } from '../../errors/problem-details.js';

export class CatsController {
  constructor(private readonly catsService: CatsService) {}

  async getStatus(
    request: FastifyRequest<{ Params: { catId: string } }>,
    reply: FastifyReply
  ) {
    const { catId } = request.params;
    const userId = request.user?.id;

    const cat = await this.catsService.findByIdAndUser(catId, userId);
    if (!cat) {
      throw new NotFoundError('Cat', catId);
    }

    return reply.send({
      id: cat.id,
      name: cat.name,
      hunger: cat.hunger,
      happiness: cat.happiness,
      affection: cat.affection,
      energy: cat.energy,
      level: cat.level,
      exp: cat.exp,
      coins: cat.coins,
      hearts: cat.hearts,
      lastSyncTime: cat.lastActiveAt
    });
  }

  async calculateOfflineProgress(
    request: FastifyRequest<{
      Params: { catId: string };
      Body: { lastActiveAt: string };
    }>,
    reply: FastifyReply
  ) {
    const { catId } = request.params;
    const { lastActiveAt } = request.body;
    const userId = request.user?.id;

    const cat = await this.catsService.findByIdAndUser(catId, userId);
    if (!cat) {
      throw new NotFoundError('Cat', catId);
    }

    const result = await this.catsService.calculateOfflineRewards(
      cat,
      new Date(lastActiveAt)
    );

    await this.catsService.applyOfflineChanges(cat.id, result);

    return reply.send(result);
  }

  async executeAction(
    request: FastifyRequest<{
      Params: { catId: string };
      Body: { type: 'feed' | 'play' | 'walk'; itemId?: string };
    }>,
    reply: FastifyReply
  ) {
    const { catId } = request.params;
    const { type, itemId } = request.body;
    const userId = request.user?.id;
    const idempotencyKey = request.headers['idempotency-key'] as string;

    if (!idempotencyKey) {
      return reply.code(400).send({
        type: 'https://api.harunyang.com/problems/missing-idempotency-key',
        title: 'Idempotency key required',
        status: 400
      });
    }

    const cached = await this.catsService.getIdempotentResponse(idempotencyKey);
    if (cached) {
      return reply.send(cached);
    }

    const cat = await this.catsService.findByIdAndUser(catId, userId);
    if (!cat) {
      throw new NotFoundError('Cat', catId);
    }

    const result = await this.catsService.executeAction(
      cat,
      type,
      itemId
    );

    await this.catsService.cacheIdempotentResponse(
      idempotencyKey,
      result,
      300
    );

    return reply.send(result);
  }
}
