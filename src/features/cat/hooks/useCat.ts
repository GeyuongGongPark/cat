import { useSuspenseQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { v4 as uuidv4 } from 'uuid';
import type { Cat, CatAction, OfflineProgressRequest, OfflineProgressResponse, CatActionResponse } from '../types/cat';

const API_BASE = process.env.NEXT_PUBLIC_API_URL || '';

function getAuthHeaders() {
  const token = localStorage.getItem('authToken');
  return {
    'Content-Type': 'application/json',
    ...(token && { Authorization: `Bearer ${token}` }),
  };
}

async function fetchCatStatus(catId: string): Promise<Cat> {
  const res = await fetch(`${API_BASE}/cats/${catId}/status`, {
    headers: getAuthHeaders(),
  });

  if (!res.ok) {
    const error: any = new Error('고양이 상태 조회 실패');
    error.status = res.status;
    if (res.status === 401) error.code = 'UNAUTHORIZED';
    if (res.status === 403) error.code = 'FORBIDDEN';
    if (res.status === 404) error.code = 'NOT_FOUND';
    throw error;
  }

  return res.json();
}

async function postOfflineProgress(
  catId: string,
  data: OfflineProgressRequest
): Promise<OfflineProgressResponse> {
  const res = await fetch(`${API_BASE}/cats/${catId}/offline-progress`, {
    method: 'POST',
    headers: getAuthHeaders(),
    body: JSON.stringify(data),
  });

  if (!res.ok) {
    const error: any = new Error('오프라인 보상 계산 실패');
    error.status = res.status;
    throw error;
  }

  return res.json();
}

async function postCatAction(
  catId: string,
  action: CatAction
): Promise<CatActionResponse> {
  const idempotencyKey = uuidv4();
  const res = await fetch(`${API_BASE}/cats/${catId}/actions`, {
    method: 'POST',
    headers: {
      ...getAuthHeaders(),
      'Idempotency-Key': idempotencyKey,
    },
    body: JSON.stringify(action),
  });

  if (!res.ok) {
    const errorData = await res.json().catch(() => ({}));
    const error: any = new Error(errorData.message || '액션 실행 실패');
    error.status = res.status;
    error.code = errorData.code;
    throw error;
  }

  return res.json();
}

export function useCatStatus(catId: string) {
  return useSuspenseQuery({
    queryKey: ['cat', catId, 'status'],
    queryFn: () => fetchCatStatus(catId),
    staleTime: 10_000,
    refetchOnWindowFocus: true,
  });
}

export function useOfflineProgress(catId: string) {
  return useMutation({
    mutationFn: (data: OfflineProgressRequest) => postOfflineProgress(catId, data),
  });
}

export function useCatAction(catId: string) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (action: CatAction) => postCatAction(catId, action),
    onSuccess: (data) => {
      queryClient.setQueryData(['cat', catId, 'status'], (old: Cat | undefined) => {
        if (!old) return old;
        return {
          ...old,
          ...data.cat,
          coins: data.balance.coins,
          hearts: data.balance.hearts,
        };
      });
    },
  });
}