import { test, expect } from '@playwright/test';

test.describe('고양이 성격 시스템 E2E 테스트', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await expect(page.getByTestId('personality-selection-screen')).toBeVisible();
  });

  test('TC_E001: 츤데레 성격 고양이 선택 시 올바른 특성 표시', async ({ page }) => {
    await page.getByTestId('personality-tsundere-btn').click();
    await expect(page.getByTestId('personality-description')).toBeVisible();
    
    const affectionText = await page.getByTestId('affection-stat').textContent();
    expect(affectionText).toMatch(/낮음|0\.3/);
    
    const energyText = await page.getByTestId('energy-stat').textContent();
    expect(energyText).toMatch(/보통|0\.6/);
    
    await page.getByTestId('confirm-btn').click();
    await expect(page.getByTestId('game-screen')).toBeVisible();
  });

  test('TC_E002: 집착형 성격 고양이 선택 시 올바른 특성 표시', async ({ page }) => {
    await page.getByTestId('personality-clingy-btn').click();
    await expect(page.getByTestId('personality-description')).toBeVisible();
    
    const affectionText = await page.getByTestId('affection-stat').textContent();
    expect(affectionText).toMatch(/매우 높음|0\.95/);
    
    const energyText = await page.getByTestId('energy-stat').textContent();
    expect(energyText).toMatch(/높음|0\.7/);
    
    await page.getByTestId('confirm-btn').click();
    await expect(page.getByTestId('game-screen')).toBeVisible();
  });

  test('TC_E003: 7종 모든 성격 선택 버튼 표시 확인', async ({ page }) => {
    await expect(page.getByTestId('personality-tsundere-btn')).toBeVisible();
    await expect(page.getByTestId('personality-clingy-btn')).toBeVisible();
    await expect(page.getByTestId('personality-lazy-btn')).toBeVisible();
    await expect(page.getByTestId('personality-hyperactive-btn')).toBeVisible();
    await expect(page.getByTestId('personality-shy-btn')).toBeVisible();
    await expect(page.getByTestId('personality-grumpy-btn')).toBeVisible();
    await expect(page.getByTestId('personality-curious-btn')).toBeVisible();
  });

  test('TC_E004: 소심형 고양이 첫 만남 스토리 표시', async ({ page }) => {
    await page.getByTestId('personality-shy-btn').click();
    await expect(page.getByTestId('first-meeting-story')).toBeVisible();
    
    const storyText = await page.getByTestId('first-meeting-story').textContent();
    expect(storyText.length).toBeGreaterThanOrEqual(20);
    expect(storyText).toMatch(/소심|조심|숨|경계/);
    
    await page.getByTestId('story-next-btn').click();
    await expect(page.getByTestId('game-screen')).toBeVisible();
  });

  test('TC_E005: 심술쟁이 고양이 첫 만남 스토리 표시', async ({ page }) => {
    await page.getByTestId('personality-grumpy-btn').click();
    await expect(page.getByTestId('first-meeting-story')).toBeVisible();
    
    const storyText = await page.getByTestId('first-meeting-story').textContent();
    expect(storyText.length).toBeGreaterThanOrEqual(20);
    expect(storyText).toMatch(/심술|퉁명|시큰둥/);
    
    await page.getByTestId('story-next-btn').click();
    await expect(page.getByTestId('game-screen')).toBeVisible();
  });

  test('TC_E006: 게으름뱅이 고양이의 맑은 날 선호도 표시', async ({ page }) => {
    await page.getByTestId('personality-lazy-btn').click();
    await page.getByTestId('confirm-btn').click();
    await expect(page.getByTestId('game-screen')).toBeVisible();
    
    await page.getByTestId('weather-info').click();
    const weatherText = await page.getByTestId('weather-preference-text').textContent();
    expect(weatherText.length).toBeGreaterThanOrEqual(5);
  });

  test('TC_E007: 과잉행동 고양이의 눈오는 날 선호도 표시', async ({ page }) => {
    await page.getByTestId('personality-hyperactive-btn').click();
    await page.getByTestId('confirm-btn').click();
    await expect(page.getByTestId('game-screen')).toBeVisible();
    
    await page.evaluate(() => {
      window.testHelpers.setWeather('snowy');
    });
    
    await page.getByTestId('weather-info').click();
    const weatherText = await page.getByTestId('weather-preference-text').textContent();
    expect(weatherText.length).toBeGreaterThanOrEqual(5);
  });

  test('TC_E008: 호기심 많은 고양이의 높은 playfulness UI 반영', async ({ page }) => {
    await page.getByTestId('personality-curious-btn').click();
    await page.getByTestId('confirm-btn').click();
    await expect(page.getByTestId('game-screen')).toBeVisible();
    
    await page.getByTestId('cat-info-panel').click();
    
    const playfulnessText = await page.getByTestId('playfulness-stat').textContent();
    expect(playfulnessText).toMatch(/높음|0\.85/);
    
    const affectionText = await page.getByTestId('affection-stat').textContent();
    expect(affectionText).toMatch(/높음|0\.7/);
  });

  test('TC_E009: 성격 선택 후 취소 시 선택 화면 복귀', async ({ page }) => {
    await page.getByTestId('personality-tsundere-btn').click();
    await expect(page.getByTestId('personality-description')).toBeVisible();
    
    await page.getByTestId('back-btn').click();
    await expect(page.getByTestId('personality-selection-screen')).toBeVisible();
  });

  test('TC_E010: 집착형 고양이의 높은 초기 affection 확인', async ({ page }) => {
    await page.getByTestId('personality-clingy-btn').click();
    await page.getByTestId('confirm-btn').click();
    await expect(page.getByTestId('game-screen')).toBeVisible();
    
    await page.getByTestId('cat-info-panel').click();
    
    const affectionText = await page.getByTestId('affection-stat').textContent();
    expect(affectionText).toMatch(/매우 높음|0\.95/);
  });

  test('TC_E011: 앱 재시작 후 츤데레 성격 유지', async ({ page }) => {
    await page.getByTestId('personality-tsundere-btn').click();
    await page.getByTestId('confirm-btn').click();
    await expect(page.getByTestId('game-screen')).toBeVisible();
    
    await page.reload();
    await expect(page.getByTestId('game-screen')).toBeVisible();
    
    await page.getByTestId('cat-info-panel').click();
    const personalityLabel = await page.getByTestId('personality-label').textContent();
    expect(personalityLabel).toContain('츤데레');
    
    const affectionText = await page.getByTestId('affection-stat').textContent();
    expect(affectionText).toMatch(/0\.3/);
  });

  test('TC_E012: 호기심 많은 고양이의 날씨별 선호도 전환', async ({ page }) => {
    await page.getByTestId('personality-curious-btn').click();
    await page.getByTestId('confirm-btn').click();
    await expect(page.getByTestId('game-screen')).toBeVisible();
    
    await page.evaluate(() => window.testHelpers.setWeather('sunny'));
    await page.getByTestId('weather-info').click();
    const sunnyText = await page.getByTestId('weather-preference-text').textContent();
    
    await page.evaluate(() => window.testHelpers.setWeather('rainy'));
    await page.getByTestId('weather-info').click();
    const rainyText = await page.getByTestId('weather-preference-text').textContent();
    
    expect(sunnyText).not.toEqual(rainyText);
    
    await page.evaluate(() => window.testHelpers.setWeather('cloudy'));
    await page.getByTestId('weather-info').click();
    const cloudyText = await page.getByTestId('weather-preference-text').textContent();
    
    expect(cloudyText).not.toEqual(rainyText);
  });
});
