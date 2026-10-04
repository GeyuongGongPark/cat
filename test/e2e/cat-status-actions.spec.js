import { test, expect } from '@playwright/test';

test.describe('고양이 상태 조회 및 액션 실행 E2E', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/game');
    await page.waitForLoadState('networkidle');
  });

  test('TC_E001: GamePage 진입 시 고양이 상태 UI 표시', async ({ page }) => {
    const container = page.getByTestId('cat-status-container');
    await expect(container).toBeVisible();
    
    const nameElement = container.locator('[data-field="name"]');
    const levelElement = container.locator('[data-field="level"]');
    const energyElement = container.locator('[data-field="energy"]');
    const hungerElement = container.locator('[data-field="hunger"]');
    
    await expect(nameElement).not.toBeEmpty();
    await expect(levelElement).not.toBeEmpty();
    await expect(energyElement).not.toBeEmpty();
    await expect(hungerElement).not.toBeEmpty();
  });

  test('TC_E002: 에너지 충분 시 먹이주기 액션 실행', async ({ page }) => {
    const container = page.getByTestId('cat-status-container');
    const feedBtn = page.getByTestId('feed-btn');
    
    const initialHunger = await container.locator('[data-field="hunger"]').textContent();
    const initialItemCount = await container.locator('[data-field="item-count"]').textContent();
    
    await feedBtn.click();
    
    await page.waitForResponse(resp => 
      resp.url().includes('/api/cat/feed') && resp.status() === 200
    );
    
    const updatedHunger = await container.locator('[data-field="hunger"]').textContent();
    const updatedItemCount = await container.locator('[data-field="item-count"]').textContent();
    
    expect(parseInt(updatedHunger!)).toBeLessThan(parseInt(initialHunger!));
    expect(parseInt(updatedItemCount!)).toBe(parseInt(initialItemCount!) - 1);
  });

  test('TC_E003: 에너지 충분 시 놀아주기 액션 실행', async ({ page }) => {
    const container = page.getByTestId('cat-status-container');
    const playBtn = page.getByTestId('play-btn');
    
    const initialEnergy = await container.locator('[data-field="energy"]').textContent();
    
    await playBtn.click();
    
    await page.waitForResponse(resp => 
      resp.url().includes('/api/cat/play') && resp.status() === 200
    );
    
    const updatedEnergy = await container.locator('[data-field="energy"]').textContent();
    
    expect(parseInt(updatedEnergy!)).toBe(parseInt(initialEnergy!) - 20);
  });

  test('TC_E004: 에너지 부족 시 놀아주기 버튼 비활성화', async ({ page }) => {
    await page.route('/api/cat/state', route => {
      route.fulfill({
        status: 200,
        body: JSON.stringify({
          id: '1',
          name: 'TestCat',
          level: 1,
          energy: 15,
          hunger: 30,
          affection: 50,
          experience: 0
        })
      });
    });
    
    await page.reload();
    await page.waitForLoadState('networkidle');
    
    const playBtn = page.getByTestId('play-btn');
    await expect(playBtn).toBeDisabled();
    
    await playBtn.click({ force: true });
    
    await expect(page.getByTestId('error-modal')).not.toBeVisible();
  });

  test('TC_E005: 에너지 부족 시 먹이주기 버튼 비활성화', async ({ page }) => {
    await page.route('/api/cat/state', route => {
      route.fulfill({
        status: 200,
        body: JSON.stringify({
          id: '1',
          name: 'TestCat',
          level: 1,
          energy: 5,
          hunger: 30,
          affection: 50,
          experience: 0
        })
      });
    });
    
    await page.reload();
    await page.waitForLoadState('networkidle');
    
    const feedBtn = page.getByTestId('feed-btn');
    await expect(feedBtn).toBeDisabled();
  });

  test('TC_E006: 에너지 부족 에러 시 경고 모달 표시', async ({ page }) => {
    await page.route('/api/cat/play', route => {
      route.fulfill({
        status: 400,
        body: JSON.stringify({
          error: 'INSUFFICIENT_ENERGY',
          message: '에너지가 부족합니다'
        })
      });
    });
    
    const playBtn = page.getByTestId('play-btn');
    await playBtn.click();
    
    const errorModal = page.getByTestId('error-modal');
    await expect(errorModal).toBeVisible();
    await expect(errorModal).toContainText('에너지가 부족합니다');
  });

  test('TC_E007: 아이템 부족 에러 시 경고 모달 표시', async ({ page }) => {
    await page.route('/api/cat/feed', route => {
      route.fulfill({
        status: 400,
        body: JSON.stringify({
          error: 'NO_ITEM',
          message: '아이템이 부족합니다'
        })
      });
    });
    
    const feedBtn = page.getByTestId('feed-btn');
    await feedBtn.click();
    
    const errorModal = page.getByTestId('error-modal');
    await expect(errorModal).toBeVisible();
    await expect(errorModal).toContainText('아이템이 부족합니다');
  });

  test('TC_E008: 10초마다 자동으로 상태 갱신', async ({ page }) => {
    let requestCount = 0;
    
    await page.route('/api/cat/state', route => {
      requestCount++;
      route.continue();
    });
    
    await page.reload();
    await page.waitForTimeout(500);
    const initialCount = requestCount;
    
    await page.waitForTimeout(10500);
    
    expect(requestCount).toBeGreaterThan(initialCount);
  });

  test('TC_E009: 앱 재진입 시 offline-progress API 호출', async ({ page }) => {
    let offlineProgressCalled = false;
    
    await page.route('/api/cat/offline-progress', route => {
      offlineProgressCalled = true;
      route.fulfill({
        status: 200,
        body: JSON.stringify({
          energy: 10,
          affection: 5,
          experience: 15
        })
      });
    });
    
    await page.evaluate(() => {
      window.dispatchEvent(new Event('blur'));
    });
    
    await page.waitForTimeout(3000);
    
    await page.evaluate(() => {
      window.dispatchEvent(new Event('focus'));
    });
    
    await page.waitForTimeout(500);
    
    expect(offlineProgressCalled).toBe(true);
  });

  test('TC_E010: 에너지 정확히 20일 때 놀아주기 실행', async ({ page }) => {
    await page.route('/api/cat/state', route => {
      route.fulfill({
        status: 200,
        body: JSON.stringify({
          id: '1',
          name: 'TestCat',
          level: 1,
          energy: 20,
          hunger: 30,
          affection: 50,
          experience: 0
        })
      });
    });
    
    await page.reload();
    await page.waitForLoadState('networkidle');
    
    const playBtn = page.getByTestId('play-btn');
    await expect(playBtn).toBeEnabled();
    
    await playBtn.click();
    
    await page.waitForResponse(resp => 
      resp.url().includes('/api/cat/play') && resp.status() === 200
    );
    
    const container = page.getByTestId('cat-status-container');
    const updatedEnergy = await container.locator('[data-field="energy"]').textContent();
    expect(parseInt(updatedEnergy!)).toBe(0);
  });

  test('TC_E011: 액션 버튼 연속 클릭 시 중복 요청 방지', async ({ page }) => {
    let requestCount = 0;
    
    await page.route('/api/cat/feed', route => {
      requestCount++;
      setTimeout(() => route.continue(), 500);
    });
    
    const feedBtn = page.getByTestId('feed-btn');
    
    await feedBtn.click();
    await feedBtn.click();
    await feedBtn.click();
    
    await page.waitForTimeout(1000);
    
    expect(requestCount).toBe(1);
  });

  test('TC_E012: 네트워크 에러 후 재시도 가능', async ({ page }) => {
    let attemptCount = 0;
    
    await page.route('/api/cat/feed', route => {
      attemptCount++;
      if (attemptCount === 1) {
        route.abort('failed');
      } else {
        route.continue();
      }
    });
    
    const feedBtn = page.getByTestId('feed-btn');
    await feedBtn.click();
    
    const errorModal = page.getByTestId('error-modal');
    await expect(errorModal).toBeVisible();
    
    const closeBtn = errorModal.getByTestId('close-btn');
    await closeBtn.click();
    
    await feedBtn.click();
    
    await page.waitForResponse(resp => 
      resp.url().includes('/api/cat/feed') && resp.status() === 200
    );
    
    expect(attemptCount).toBe(2);
  });

  test('TC_E013: 상태 조회 실패 시 재시도 후 에러 표시', async ({ page }) => {
    let attemptCount = 0;
    
    await page.route('/api/cat/state', route => {
      attemptCount++;
      route.fulfill({
        status: 500,
        body: JSON.stringify({ error: 'Internal Server Error' })
      });
    });
    
    await page.goto('/game');
    
    await page.waitForTimeout(3000);
    
    expect(attemptCount).toBeGreaterThanOrEqual(3);
    
    const errorModal = page.getByTestId('error-modal');
    await expect(errorModal).toBeVisible();
  });

  test('TC_E014: 에너지 100일 때 먹이주기 실행 불가', async ({ page }) => {
    await page.route('/api/cat/state', route => {
      route.fulfill({
        status: 200,
        body: JSON.stringify({
          id: '1',
          name: 'TestCat',
          level: 1,
          energy: 100,
          hunger: 30,
          affection: 50,
          experience: 0
        })
      });
    });
    
    await page.reload();
    await page.waitForLoadState('networkidle');
    
    const feedBtn = page.getByTestId('feed-btn');
    await expect(feedBtn).toBeDisabled();
  });

  test('TC_E015: 배고픔 0일 때 먹이주기 실행 불가', async ({ page }) => {
    await page.route('/api/cat/state', route => {
      route.fulfill({
        status: 200,
        body: JSON.stringify({
          id: '1',
          name: 'TestCat',
          level: 1,
          energy: 50,
          hunger: 0,
          affection: 50,
          experience: 0
        })
      });
    });
    
    await page.reload();
    await page.waitForLoadState('networkidle');
    
    const feedBtn = page.getByTestId('feed-btn');
    await expect(feedBtn).toBeDisabled();
  });
});