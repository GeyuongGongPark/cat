import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

const errorRate = new Rate('errors');
const responseTime = new Trend('response_time');

const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000';

const PERSONALITIES = [
  'TSUNDERE', 'CLINGY', 'LAZY', 'HYPERACTIVE',
  'SHY', 'GRUMPY', 'CURIOUS'
];

function randomPersonality() {
  return PERSONALITIES[Math.floor(Math.random() * PERSONALITIES.length)];
}

export const options = {
  scenarios: {
    // TC_P001, P002, P003: 정상 부하 테스트
    normal_load: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '2m', target: 100 },
        { duration: '5m', target: 100 },
        { duration: '2m', target: 0 },
      ],
      gracefulRampDown: '30s',
      exec: 'normalLoad',
    },
    // TC_P004: CatState 생성 부하 테스트
    catstate_load: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '3m', target: 200 },
        { duration: '5m', target: 200 },
        { duration: '2m', target: 0 },
      ],
      gracefulRampDown: '30s',
      exec: 'catStateLoad',
      startTime: '10m',
    },
    // TC_P005: 스파이크 테스트
    spike_test: {
      executor: 'ramping-vus',
      startVUs: 10,
      stages: [
        { duration: '30s', target: 1000 },
        { duration: '2m', target: 1000 },
        { duration: '30s', target: 10 },
        { duration: '2m', target: 10 },
      ],
      gracefulRampDown: '30s',
      exec: 'spikeTest',
      startTime: '21m',
    },
    // TC_P010: 복합 시나리오 플로우 테스트
    end_to_end_flow: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '2m', target: 100 },
        { duration: '5m', target: 100 },
        { duration: '2m', target: 0 },
      ],
      gracefulRampDown: '30s',
      exec: 'endToEndFlow',
      startTime: '27m',
    },
  },
  thresholds: {
    'http_req_duration': ['p(95)<200', 'p(99)<400'],
    'http_req_failed': ['rate<0.01'],
    'errors': ['rate<0.01'],
    'http_reqs': ['rate>100'],
  },
};

export function normalLoad() {
  // TC_P007: POST /api/cat/select
  const selectPayload = JSON.stringify({
    personality: randomPersonality(),
    userId: `user_${__VU}`,
  });

  const selectRes = http.post(`${BASE_URL}/api/cat/select`, selectPayload, {
    headers: { 'Content-Type': 'application/json' },
  });

  const selectSuccess = check(selectRes, {
    'select status 200': (r) => r.status === 200,
    'select response < 200ms': (r) => r.timings.duration < 200,
    'select has catId': (r) => r.json('catId') !== undefined,
  });

  errorRate.add(!selectSuccess);
  responseTime.add(selectRes.timings.duration);

  sleep(1);

  // TC_P008: GET /api/cat/personality
  const catId = selectRes.json('catId');
  const personalityRes = http.get(`${BASE_URL}/api/cat/personality?catId=${catId}`);

  const personalitySuccess = check(personalityRes, {
    'personality status 200': (r) => r.status === 200,
    'personality response < 50ms': (r) => r.timings.duration < 50,
    'personality has traits': (r) => r.json('traits') !== undefined,
  });

  errorRate.add(!personalitySuccess);
  responseTime.add(personalityRes.timings.duration);

  sleep(1);

  // TC_P009: GET /api/cat/weather-preference
  const weathers = ['sunny', 'rainy', 'cloudy', 'snowy'];
  const weather = weathers[Math.floor(Math.random() * weathers.length)];
  
  const weatherRes = http.get(
    `${BASE_URL}/api/cat/weather-preference?catId=${catId}&weather=${weather}`
  );

  const weatherSuccess = check(weatherRes, {
    'weather status 200': (r) => r.status === 200,
    'weather response < 100ms': (r) => r.timings.duration < 100,
    'weather has text': (r) => r.json('text') !== undefined && r.json('text').length > 5,
  });

  errorRate.add(!weatherSuccess);
  responseTime.add(weatherRes.timings.duration);

  sleep(1);
}

export function catStateLoad() {
  // TC_P004: CatState.withPersonality() 성능
  const personality = randomPersonality();
  const payload = JSON.stringify({ personality });

  const res = http.post(`${BASE_URL}/api/cat/state`, payload, {
    headers: { 'Content-Type': 'application/json' },
  });

  const success = check(res, {
    'state status 200': (r) => r.status === 200,
    'state response < 25ms': (r) => r.timings.duration < 25,
    'state has complete data': (r) => {
      const data = r.json();
      return data.personality && data.traits && data.traits.affection !== undefined;
    },
  });

  errorRate.add(!success);
  responseTime.add(res.timings.duration);

  sleep(0.5);
}

export function spikeTest() {
  // TC_P005: 스파이크 테스트
  const personality = randomPersonality();
  const payload = JSON.stringify({
    personality,
    userId: `spike_user_${__VU}`,
  });

  const res = http.post(`${BASE_URL}/api/cat/select`, payload, {
    headers: { 'Content-Type': 'application/json' },
  });

  const success = check(res, {
    'spike status 200 or 429': (r) => r.status === 200 || r.status === 429,
    'spike response < 100ms or retry': (r) => r.timings.duration < 100 || r.status === 429,
  });

  errorRate.add(!success);
  responseTime.add(res.timings.duration);

  sleep(0.1);
}

export function endToEndFlow() {
  // TC_P010: 전체 플로우 성능 검증
  const flowStart = Date.now();
  
  // 1. 고양이 선택
  const selectPayload = JSON.stringify({
    personality: randomPersonality(),
    userId: `flow_user_${__VU}`,
  });

  const selectRes = http.post(`${BASE_URL}/api/cat/select`, selectPayload, {
    headers: { 'Content-Type': 'application/json' },
  });

  if (selectRes.status !== 200) {
    errorRate.add(1);
    return;
  }

  const catId = selectRes.json('catId');
  
  // 2. 성격 정보 조회
  const personalityRes = http.get(`${BASE_URL}/api/cat/personality?catId=${catId}`);
  
  if (personalityRes.status !== 200) {
    errorRate.add(1);
    return;
  }
  
  // 3. 날씨 선호도 조회
  const weather = ['sunny', 'rainy', 'cloudy', 'snowy'][Math.floor(Math.random() * 4)];
  const weatherRes = http.get(
    `${BASE_URL}/api/cat/weather-preference?catId=${catId}&weather=${weather}`
  );
  
  const flowDuration = Date.now() - flowStart;
  
  const flowSuccess = check(weatherRes, {
    'flow completed successfully': (r) => r.status === 200,
    'flow total time < 400ms': () => flowDuration < 400,
    'flow has all data': (r) => {
      return selectRes.json('catId') &&
             personalityRes.json('traits') &&
             r.json('text');
    },
  });

  errorRate.add(!flowSuccess);
  responseTime.add(flowDuration);

  sleep(1);
}
