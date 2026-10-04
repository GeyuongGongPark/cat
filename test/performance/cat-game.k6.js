import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

const errorRate = new Rate('errors');
const getCatStateDuration = new Trend('get_cat_state_duration');
const feedCatDuration = new Trend('feed_cat_duration');
const playCatDuration = new Trend('play_cat_duration');
const offlineProgressDuration = new Trend('offline_progress_duration');

const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000';

export const options = {
  scenarios: {
    normal_load: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '2m', target: 100 },
        { duration: '5m', target: 100 },
        { duration: '2m', target: 0 },
      ],
      gracefulRampDown: '30s',
    },
  },
  thresholds: {
    http_req_duration: ['p(95)<500'],
    http_req_failed: ['rate<0.01'],
    errors: ['rate<0.01'],
    get_cat_state_duration: ['p(95)<500'],
    feed_cat_duration: ['p(95)<800'],
    play_cat_duration: ['p(95)<800'],
    offline_progress_duration: ['p(95)<1000'],
  },
};

const headers = {
  'Content-Type': 'application/json',
};

function login() {
  const loginRes = http.post(
    `${BASE_URL}/api/auth/login`,
    JSON.stringify({
      email: 'test@example.com',
      password: 'password123',
    }),
    { headers }
  );

  const loginSuccess = check(loginRes, {
    'login status 200': (r) => r.status === 200,
    'login has token': (r) => r.json('token') !== undefined,
  });

  errorRate.add(!loginSuccess);

  if (loginSuccess) {
    return loginRes.json('token');
  }
  return null;
}

function getCatState(token) {
  const res = http.get(`${BASE_URL}/api/cat/state`, {
    headers: { ...headers, Authorization: `Bearer ${token}` },
  });

  const success = check(res, {
    'getCatState status 200': (r) => r.status === 200,
    'getCatState has id': (r) => r.json('id') !== undefined,
    'getCatState response < 500ms': (r) => r.timings.duration < 500,
  });

  getCatStateDuration.add(res.timings.duration);
  errorRate.add(!success);

  return res;
}

function feedCat(token) {
  const res = http.post(
    `${BASE_URL}/api/cat/feed`,
    null,
    { headers: { ...headers, Authorization: `Bearer ${token}` } }
  );

  const success = check(res, {
    'feedCat status 200 or 400': (r) => r.status === 200 || r.status === 400,
    'feedCat response < 800ms': (r) => r.timings.duration < 800,
  });

  feedCatDuration.add(res.timings.duration);
  errorRate.add(!success);

  return res;
}

function playCat(token) {
  const res = http.post(
    `${BASE_URL}/api/cat/play`,
    null,
    { headers: { ...headers, Authorization: `Bearer ${token}` } }
  );

  const success = check(res, {
    'playCat status 200 or 400': (r) => r.status === 200 || r.status === 400,
    'playCat response < 800ms': (r) => r.timings.duration < 800,
  });

  playCatDuration.add(res.timings.duration);
  errorRate.add(!success);

  return res;
}

function offlineProgress(token) {
  const offlineMinutes = Math.floor(Math.random() * 1440) + 1;
  const res = http.post(
    `${BASE_URL}/api/cat/offline-progress`,
    JSON.stringify({ offlineMinutes }),
    { headers: { ...headers, Authorization: `Bearer ${token}` } }
  );

  const success = check(res, {
    'offlineProgress status 200': (r) => r.status === 200,
    'offlineProgress response < 1000ms': (r) => r.timings.duration < 1000,
  });

  offlineProgressDuration.add(res.timings.duration);
  errorRate.add(!success);

  return res;
}

export default function () {
  const token = login();

  if (!token) {
    sleep(1);
    return;
  }

  getCatState(token);
  sleep(3);

  const action = Math.random();
  if (action < 0.5) {
    feedCat(token);
  } else {
    playCat(token);
  }

  sleep(5);

  if (Math.random() < 0.2) {
    offlineProgress(token);
    sleep(2);
  }
}