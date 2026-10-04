import { useEffect, useState } from 'react';
import { useSuspenseQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Progress } from '@/components/ui/progress';
import { Heart, Coins, Zap, Smile } from 'lucide-react';
import { overlay } from 'overlay-kit';
import { useCatStatus, useCatAction, useOfflineProgress } from '../hooks/useCat';
import { OfflineRewardModal } from './OfflineRewardModal';
import type { CatAction } from '../types/cat';

interface CatStatusProps {
  catId: string;
}

export function CatStatus({ catId }: CatStatusProps) {
  const queryClient = useQueryClient();
  const { data: cat } = useCatStatus(catId);
  const catAction = useCatAction(catId);
  const offlineProgress = useOfflineProgress(catId);
  const [isOnline, setIsOnline] = useState(true);

  // 10초 폴링
  useEffect(() => {
    const interval = setInterval(() => {
      queryClient.invalidateQueries({ queryKey: ['cat', catId, 'status'] });
    }, 10_000);

    return () => clearInterval(interval);
  }, [catId, queryClient]);

  // 온라인/오프라인 감지
  useEffect(() => {
    const handleOnline = () => setIsOnline(true);
    const handleOffline = () => setIsOnline(false);

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);

    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, []);

  // 앱 재진입 시 오프라인 보상 체크
  useEffect(() => {
    const handleVisibilityChange = async () => {
      if (document.visibilityState === 'visible') {
        const lastActiveAt = localStorage.getItem('lastActiveAt');
        if (lastActiveAt) {
          const result = await offlineProgress.mutateAsync({
            lastActiveAt: new Date(lastActiveAt).toISOString(),
          });

          if (result.durationSeconds > 0) {
            overlay.open(({ isOpen, close }) => (
              <OfflineRewardModal
                open={isOpen}
                onClose={close}
                rewards={result.rewards}
                events={result.events}
                duration={result.durationSeconds}
              />
            ));
          }
        }
        localStorage.setItem('lastActiveAt', new Date().toISOString());
      }
    };

    document.addEventListener('visibilitychange', handleVisibilityChange);
    return () => document.removeEventListener('visibilitychange', handleVisibilityChange);
  }, [offlineProgress]);

  const handleAction = async (type: CatAction['type'], itemId?: string) => {
    if (!isOnline) {
      overlay.open(({ isOpen, close }) => (
        <div data-testid="offline-warning" className="p-4 bg-yellow-50 rounded-md">
          <p className="text-yellow-800">오프라인 상태에서는 액션을 실행할 수 없습니다.</p>
          <Button onClick={close} className="mt-2">확인</Button>
        </div>
      ));
      return;
    }

    try {
      await catAction.mutateAsync({ type, itemId });
    } catch (error: any) {
      const errorMessage = {
        INSUFFICIENT_ENERGY: '에너지가 부족합니다!',
        NO_ITEM: '먹이를 선택해주세요.',
      }[error.code] || '액션 실행에 실패했습니다.';

      overlay.open(({ isOpen, close }) => (
        <div data-testid="action-error" className="p-4 bg-red-50 rounded-md">
          <p className="text-red-800">{errorMessage}</p>
          <Button onClick={close} variant="destructive" className="mt-2">확인</Button>
        </div>
      ));
    }
  };

  const isActionDisabled = !isOnline || catAction.isPending;
  const canPlay = cat.energy >= 20;
  const canFeed = cat.hunger < 100;

  return (
    <Card data-testid="cat-status-container" className="p-6 space-y-6">
      <div className="flex items-center justify-between">
        <div className="space-y-1">
          <h2 data-testid="cat-name" className="text-2xl font-bold">{cat.name}</h2>
          <p className="text-sm text-gray-500">레벨 {cat.level}</p>
        </div>
        <div className="flex gap-4">
          <div data-testid="coins-display" className="flex items-center gap-1">
            <Coins className="h-5 w-5 text-yellow-500" />
            <span className="font-semibold">{cat.coins}</span>
          </div>
          <div data-testid="hearts-display" className="flex items-center gap-1">
            <Heart className="h-5 w-5 text-red-500" />
            <span className="font-semibold">{cat.hearts}</span>
          </div>
        </div>
      </div>

      <div className="space-y-3">
        <div data-testid="hunger-stat">
          <div className="flex justify-between mb-1">
            <span className="text-sm font-medium">배고픔</span>
            <span className="text-sm text-gray-500">{cat.hunger}/100</span>
          </div>
          <Progress value={cat.hunger} className="h-2" />
        </div>

        <div data-testid="happiness-stat">
          <div className="flex justify-between mb-1">
            <span className="text-sm font-medium">행복도</span>
            <span className="text-sm text-gray-500">{cat.happiness}/100</span>
          </div>
          <Progress value={cat.happiness} className="h-2" />
        </div>

        <div data-testid="energy-stat">
          <div className="flex justify-between mb-1">
            <span className="text-sm font-medium">에너지</span>
            <span className="text-sm text-gray-500">{cat.energy}/100</span>
          </div>
          <Progress value={cat.energy} className="h-2" />
        </div>

        <div data-testid="affection-stat">
          <div className="flex justify-between mb-1">
            <span className="text-sm font-medium">애정도</span>
            <span className="text-sm text-gray-500">{cat.affection}/100</span>
          </div>
          <Progress value={cat.affection} className="h-2" />
        </div>
      </div>

      <div data-testid="exp-progress">
        <div className="flex justify-between mb-1">
          <span className="text-sm font-medium">경험치</span>
          <span className="text-sm text-gray-500">{cat.exp}/1000</span>
        </div>
        <Progress value={(cat.exp / 1000) * 100} className="h-2" />
      </div>

      <div className="grid grid-cols-2 gap-2">
        <Button
          data-testid="feed-btn"
          onClick={() => handleAction('feed', 'default-food')}
          disabled={isActionDisabled || !canFeed}
          variant="primary"
          size="lg"
        >
          {catAction.isPending ? '먹이는 중...' : '먹이 주기'}
        </Button>

        <Button
          data-testid="play-btn"
          onClick={() => handleAction('play')}
          disabled={isActionDisabled || !canPlay}
          variant="secondary"
          size="lg"
        >
          <Zap className="mr-2 h-4 w-4" />
          {catAction.isPending ? '노는 중...' : '놀아주기'}
        </Button>
      </div>

      {!isOnline && (
        <div data-testid="offline-indicator" className="text-center text-sm text-yellow-600">
          오프라인 상태입니다. 액션을 실행할 수 없습니다.
        </div>
      )}
    </Card>
  );
}