const { test, expect } = require('@playwright/test');

test.describe('DialogueCubit E2E Tests', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
  });

  test('TC_E001: 날씨 선택 후 첫 번째 대화 표시', async ({ page }) => {
    await page.getByTestId('weather-sunny-button').click();
    await expect(page.getByTestId('dialogue-text')).toBeVisible();
    await expect(page.getByTestId('choice-buttons-container')).toBeVisible();
    const choiceButtons = page.getByTestId('choice-button');
    await expect(choiceButtons.first()).toBeVisible();
  });

  test('TC_E002: 선택지 클릭 시 다음 대화로 진행', async ({ page }) => {
    await page.getByTestId('weather-sunny-button').click();
    await expect(page.getByTestId('dialogue-text')).toBeVisible();
    
    const firstDialogueText = await page.getByTestId('dialogue-text').textContent();
    await page.getByTestId('choice-button').first().click();
    
    await expect(page.getByTestId('dialogue-text')).toBeVisible();
    const secondDialogueText = await page.getByTestId('dialogue-text').textContent();
    expect(secondDialogueText).not.toBe(firstDialogueText);
  });

  test('TC_E003: 모든 대화 완료 후 매칭 결과 표시', async ({ page }) => {
    await page.getByTestId('weather-sunny-button').click();
    
    let dialogueIndex = 0;
    while (dialogueIndex < 5) {
      await expect(page.getByTestId('dialogue-text')).toBeVisible();
      const choiceButtons = page.getByTestId('choice-button');
      await choiceButtons.first().click();
      dialogueIndex++;
    }
    
    await expect(page.getByTestId('loading-indicator')).toBeVisible({ timeout: 2000 });
    await expect(page.getByTestId('matching-result-container')).toBeVisible({ timeout: 10000 });
    await expect(page.getByTestId('cat-personality-name')).toBeVisible();
    await expect(page.getByTestId('cat-personality-description')).toBeVisible();
  });

  test('TC_E004: rainy 날씨 선택 시 대응 대화 진행', async ({ page }) => {
    await page.getByTestId('weather-rainy-button').click();
    await expect(page.getByTestId('dialogue-text')).toBeVisible();
    
    const dialogueText = await page.getByTestId('dialogue-text').textContent();
    expect(dialogueText.toLowerCase()).toMatch(/rain|비|습/i);
    
    let dialogueIndex = 0;
    while (dialogueIndex < 5) {
      await page.getByTestId('choice-button').first().click();
      dialogueIndex++;
    }
    
    await expect(page.getByTestId('matching-result-container')).toBeVisible({ timeout: 10000 });
  });

  test('TC_E005: 선택지 버튼 활성화 상태 확인', async ({ page }) => {
    await page.getByTestId('weather-sunny-button').click();
    await expect(page.getByTestId('dialogue-text')).toBeVisible();
    
    const choiceButton = page.getByTestId('choice-button').first();
    await expect(choiceButton).toBeEnabled();
    await choiceButton.click();
    
    await expect(page.getByTestId('dialogue-text')).toBeVisible();
  });

  test('TC_E006: 매칭 계산 중 로딩 인디케이터 표시', async ({ page }) => {
    await page.getByTestId('weather-sunny-button').click();
    
    let dialogueIndex = 0;
    while (dialogueIndex < 5) {
      await page.getByTestId('choice-button').first().click();
      dialogueIndex++;
    }
    
    await expect(page.getByTestId('loading-indicator')).toBeVisible({ timeout: 2000 });
    await expect(page.getByTestId('matching-result-container')).toBeVisible({ timeout: 10000 });
    await expect(page.getByTestId('loading-indicator')).not.toBeVisible();
  });

  test('TC_E007: 서버 에러 시 에러 메시지 표시', async ({ page }) => {
    await page.route('**/api/match-personality', route => {
      route.fulfill({
        status: 500,
        body: JSON.stringify({ error: 'Internal Server Error' }),
      });
    });
    
    await page.getByTestId('weather-sunny-button').click();
    
    let dialogueIndex = 0;
    while (dialogueIndex < 5) {
      await page.getByTestId('choice-button').first().click();
      dialogueIndex++;
    }
    
    await expect(page.getByTestId('error-message')).toBeVisible({ timeout: 10000 });
    await expect(page.getByTestId('retry-button')).toBeVisible();
  });

  test('TC_E008: 에러 발생 후 재시도 성공', async ({ page }) => {
    let isFirstCall = true;
    await page.route('**/api/match-personality', route => {
      if (isFirstCall) {
        isFirstCall = false;
        route.fulfill({ status: 500, body: JSON.stringify({ error: 'Error' }) });
      } else {
        route.continue();
      }
    });
    
    await page.getByTestId('weather-sunny-button').click();
    
    let dialogueIndex = 0;
    while (dialogueIndex < 5) {
      await page.getByTestId('choice-button').first().click();
      dialogueIndex++;
    }
    
    await expect(page.getByTestId('error-message')).toBeVisible({ timeout: 10000 });
    await page.getByTestId('retry-button').click();
    
    await expect(page.getByTestId('loading-indicator')).toBeVisible({ timeout: 2000 });
    await expect(page.getByTestId('matching-result-container')).toBeVisible({ timeout: 10000 });
  });

  test('TC_E009: 대화 진행 중 새로고침 시 초기화', async ({ page }) => {
    await page.getByTestId('weather-sunny-button').click();
    await page.getByTestId('choice-button').first().click();
    await page.getByTestId('choice-button').first().click();
    
    await page.reload();
    
    await expect(page.getByTestId('weather-sunny-button')).toBeVisible();
    await expect(page.getByTestId('weather-rainy-button')).toBeVisible();
  });

  test('TC_E010: 대화 중 뒤로가기 동작', async ({ page }) => {
    await page.getByTestId('weather-sunny-button').click();
    await page.getByTestId('choice-button').first().click();
    await page.getByTestId('choice-button').first().click();
    
    await page.goBack();
    
    const isWeatherVisible = await page.getByTestId('weather-sunny-button').isVisible();
    const isDialogueVisible = await page.getByTestId('dialogue-text').isVisible();
    expect(isWeatherVisible || isDialogueVisible).toBe(true);
  });

  test('TC_E011: 선택지 중복 클릭 방지', async ({ page }) => {
    await page.getByTestId('weather-sunny-button').click();
    await expect(page.getByTestId('dialogue-text')).toBeVisible();
    
    const firstDialogueText = await page.getByTestId('dialogue-text').textContent();
    const choiceButton = page.getByTestId('choice-button').first();
    
    await choiceButton.click();
    await choiceButton.click();
    
    await expect(page.getByTestId('dialogue-text')).toBeVisible();
    const secondDialogueText = await page.getByTestId('dialogue-text').textContent();
    expect(secondDialogueText).not.toBe(firstDialogueText);
    
    await page.waitForTimeout(500);
    const thirdDialogueText = await page.getByTestId('dialogue-text').textContent();
    expect(thirdDialogueText).toBe(secondDialogueText);
  });

  test('TC_E012: cheeseTabi 성격 매칭 검증', async ({ page }) => {
    await page.getByTestId('weather-sunny-button').click();
    
    const cheeseTabiChoices = [0, 1, 0, 1, 0];
    for (let i = 0; i < cheeseTabiChoices.length; i++) {
      await expect(page.getByTestId('dialogue-text')).toBeVisible();
      const choiceButtons = page.getByTestId('choice-button');
      await choiceButtons.nth(cheeseTabiChoices[i]).click();
    }
    
    await expect(page.getByTestId('matching-result-container')).toBeVisible({ timeout: 10000 });
    const personalityName = await page.getByTestId('cat-personality-name').textContent();
    expect(personalityName.toLowerCase()).toContain('cheese');
  });

  test('TC_E013: 키보드 네비게이션으로 대화 진행', async ({ page }) => {
    await page.getByTestId('weather-sunny-button').click();
    await expect(page.getByTestId('dialogue-text')).toBeVisible();
    
    await page.keyboard.press('Tab');
    const firstChoiceButton = page.getByTestId('choice-button').first();
    await expect(firstChoiceButton).toBeFocused();
    
    await page.keyboard.press('Enter');
    await expect(page.getByTestId('dialogue-text')).toBeVisible();
    
    await page.keyboard.press('Tab');
    await page.keyboard.press('Enter');
    await expect(page.getByTestId('dialogue-text')).toBeVisible();
  });
});