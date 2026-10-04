import http from 'k6/http';
import { check, sleep } from 'k6';
import { Rate } from 'k6/metrics';

const errorRate = new Rate('errors');
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
      exec: 'normalLoad',
    },
    peak_load: {
      executor: 'ramping-vus',
      startVUs: 0,
      startTime: '10m',
      stages: [
        { duration: '1m', target: 100 },
        { duration: '2m', target: 300 },
        { duration: '5m', target: 300 },
        { duration: '2m', target: 0 },
      ],
      exec: 'peakLoad',
    },
    spike_test: {
      executor: 'ramping-vus',
      startVUs: 100,
      startTime: '22m',
      stages: [
        { duration: '1m', target: 100 },
        { duration: '10s', target: 500 },
        { duration: '3m', target: 500 },
        { duration: '10s', target: 100 },
        { duration: '1m', target: 0 },
      ],
      exec: 'spikeTest',
    },
    soak_test: {
      executor: 'constant-vus',
      vus: 50,
      duration: '30m',
      startTime: '28m',
      exec: 'soakTest',
    },
    dialogue_load: {
      executor: 'ramping-vus',
      startVUs: 0,
      startTime: '60m',
      stages: [
        { duration: '2m', target: 200 },
        { duration: '5m', target: 200 },
        { duration: '2m', target: 0 },
      ],
      exec: 'dialogueLoad',
    },
    user_journey: {
      executor: 'constant-vus',
      vus: 150,
      duration: '5m',
      startTime: '70m',
      exec: 'userJourneyTest',
    },
    db_query_load: {
      executor: 'constant-vus',
      vus: 200,
      duration: '5m',
      startTime: '76m',
      exec: 'dbQueryLoad',
    },
    concurrency_test: {
      executor: 'per-vu-iterations',
      vus: 10,
      iterations: 1,
      startTime: '82m',
      exec: 'concurrencyTest',
    },
    network_delay: {
      executor: 'constant-vus',
      vus: 50,
      duration: '3m',
      startTime: '83m',
      exec: 'networkDelayTest',
    },
  },
  thresholds: {
    'http_req_duration{scenario:normal_load}': ['p(95)<500'],
    'http_req_duration{scenario:peak_load}': ['p(95)<1000'],
    'http_req_duration{scenario:spike_test}': ['p(95)<1500'],
    'http_req_duration{scenario:soak_test}': ['p(95)<600'],
    'http_req_duration{scenario:dialogue_load}': ['p(95)<300'],
    'http_req_duration{scenario:db_query_load}': ['p(95)<400'],
    'http_req_duration{scenario:network_delay}': ['p(95)<1500'],
    'http_req_failed{scenario:normal_load}': ['rate<0.01'],
    'http_req_failed{scenario:peak_load}': ['rate<0.05'],
    'http_req_failed{scenario:spike_test}': ['rate<0.10'],
    'http_req_failed{scenario:user_journey}': ['rate<0.02'],
    errors: ['rate<0.05'],
  },
};

export function normalLoad() {
  const traits = {
    playful: Math.floor(Math.random() * 20),
    independent: Math.floor(Math.random() * 20),
    affectionate: Math.floor(Math.random() * 20),
  };

  const res = http.post(
    `${BASE_URL}/api/match-personality`,
    JSON.stringify({ traits }),
    {
      headers: { 'Content-Type': 'application/json' },
      tags: { scenario: 'normal_load' },
    }
  );

  const success = check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 500ms': (r) => r.timings.duration < 500,
    'has personality': (r) => r.json('personality') !== undefined,
  });

  errorRate.add(!success);
  sleep(1);
}

export function peakLoad() {
  const traits = {
    playful: Math.floor(Math.random() * 20),
    independent: Math.floor(Math.random() * 20),
    affectionate: Math.floor(Math.random() * 20),
  };

  const res = http.post(
    `${BASE_URL}/api/match-personality`,
    JSON.stringify({ traits }),
    {
      headers: { 'Content-Type': 'application/json' },
      tags: { scenario: 'peak_load' },
    }
  );

  const success = check(res, {
    'status is 200': (r) => r.status === 200,
    'response time < 1000ms': (r) => r.timings.duration < 1000,
  });

  errorRate.add(!success);
  sleep(0.5);
}

export function spikeTest() {
  const res = http.post(
    `${BASE_URL}/api/match-personality`,
    JSON.stringify({
      traits: {
        playful: 15,
        independent: 10,
        affectionate: 8,
      },
    }),
    {
      headers: { 'Content-Type': 'application/json' },
      tags: { scenario: 'spike_test' },
    }
  );

  check(res, {
    'spike status is 200': (r) => r.status === 200,
    'spike response time < 1500ms': (r) => r.timings.duration < 1500,
  });

  sleep(0.3);
}

export function soakTest() {
  const res = http.post(
    `${BASE_URL}/api/match-personality`,
    JSON.stringify({
      traits: {
        playful: 12,
        independent: 12,
        affectionate: 12,
      },
    }),
    {
      headers: { 'Content-Type': 'application/json' },
      tags: { scenario: 'soak_test' },
    }
  );

  check(res, {
    'soak status is 200': (r) => r.status === 200,
    'soak response time < 600ms': (r) => r.timings.duration < 600,
  });

  sleep(2);
}

export function dialogueLoad() {
  const res = http.post(
    `${BASE_URL}/api/dialogue/progress`,
    JSON.stringify({ choiceId: `choice_${Math.floor(Math.random() * 10)}` }),
    {
      headers: { 'Content-Type': 'application/json' },
      tags: { scenario: 'dialogue_load' },
    }
  );

  check(res, {
    'dialogue status is 200': (r) => r.status === 200,
    'dialogue response < 300ms': (r) => r.timings.duration < 300,
  });

  sleep(1);
}

export function userJourneyTest() {
  const weatherRes = http.post(
    `${BASE_URL}/api/weather/select`,
    JSON.stringify({ weather: 'sunny' }),
    {
      headers: { 'Content-Type': 'application/json' },
      tags: { scenario: 'user_journey' },
    }
  );

  check(weatherRes, {
    'weather selection status 200': (r) => r.status === 200,
    'weather response < 200ms': (r) => r.timings.duration < 200,
  });

  sleep(1);

  for (let i = 0; i < 5; i++) {
    const dialogueRes = http.post(
      `${BASE_URL}/api/dialogue/progress`,
      JSON.stringify({ choiceId: `choice_${i}` }),
      {
        headers: { 'Content-Type': 'application/json' },
        tags: { scenario: 'user_journey' },
      }
    );

    check(dialogueRes, {
      'dialogue status 200': (r) => r.status === 200,
      'dialogue response < 300ms': (r) => r.timings.duration < 300,
    });

    sleep(1);
  }

  const matchRes = http.post(
    `${BASE_URL}/api/match-personality`,
    JSON.stringify({
      traits: {
        playful: 15,
        independent: 10,
        affectionate: 12,
      },
    }),
    {
      headers: { 'Content-Type': 'application/json' },
      tags: { scenario: 'user_journey' },
    }
  );

  check(matchRes, {
    'match status 200': (r) => r.status === 200,
    'match response < 500ms': (r) => r.timings.duration < 500,
  });

  sleep(2);
}

export function dbQueryLoad() {
  const res = http.get(
    `${BASE_URL}/api/match-personality/result/${Math.floor(Math.random() * 1000)}`,
    {
      tags: { scenario: 'db_query_load' },
    }
  );

  check(res, {
    'db query status is 200': (r) => r.status === 200,
    'db query response < 400ms': (r) => r.timings.duration < 400,
  });

  sleep(1);
}

export function concurrencyTest() {
  const requests = [];
  const traits = {
    playful: 15,
    independent: 10,
    affectionate: 8,
  };

  for (let i = 0; i < 5; i++) {
    requests.push([
      'POST',
      `${BASE_URL}/api/match-personality`,
      JSON.stringify({ traits }),
      { headers: { 'Content-Type': 'application/json' } },
    ]);
  }

  const responses = http.batch(requests);
  const results = responses.map((r) => r.json('personality'));

  check(responses[0], {
    'concurrency all same result': () => results.every((r) => r === results[0]),
    'concurrency all status 200': () => responses.every((r) => r.status === 200),
  });
}

export function networkDelayTest() {
  const res = http.post(
    `${BASE_URL}/api/match-personality`,
    JSON.stringify({
      traits: {
        playful: 12,
        independent: 11,
        affectionate: 10,
      },
    }),
    {
      headers: { 'Content-Type': 'application/json' },
      tags: { scenario: 'network_delay' },
      timeout: '3s',
    }
  );

  check(res, {
    'network delay status is 200': (r) => r.status === 200,
    'network delay response < 1500ms': (r) => r.timings.duration < 1500,
    'network delay no timeout': (r) => r.error === '',
  });

  sleep(1);
}