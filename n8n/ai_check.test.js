const assert = require('node:assert/strict');
const { checkAiOutput } = require('./ai_check');

const payload = {
  kpis: {
    eligible_orders: 62897,
    late_orders: 36048,
    delay_rate_pct: 57.31,
  },
  exceptions: [],
};

function fullText(extra = '') {
  return `1) Executive summary
Overall delay rate is 57.31%.

2) Material changes
No material changes identified.

3) Exceptions
No exceptions found.

4) Evidence
Eligible orders: 62,897.
Late orders: 36048.

5) Questions for investigation
${extra}`;
}

// 1. Good text passes
{
  const result = checkAiOutput(fullText(), payload);

  assert.equal(result.ok, true);
  assert.deepEqual(result.problems, []);
}

// 2. Invented number is rejected
{
  const result = checkAiOutput(
    fullText('The latest rate was 58%.'),
    payload
  );

  assert.equal(result.ok, false);
  assert.ok(
    result.problems.some((p) =>
      p.includes('Invented or unsupported number')
    )
  );
}

// 3. Invented cause is rejected
{
  const result = checkAiOutput(
    `1) Executive summary
The delay rate is 57.31% because of warehouse congestion.

2) Material changes
No material changes identified.

3) Exceptions
No exceptions found.

4) Evidence
Eligible orders: 62,897.

5) Questions for investigation
Investigate warehouse capacity.`,
    payload
  );

  assert.equal(result.ok, false);
  assert.ok(
    result.problems.some((p) =>
      p.includes('Unsupported causal language')
    )
  );
}

// 4. Missing section is rejected
{
  const result = checkAiOutput(
    `1) Executive summary
Delay rate is 57.31%.

2) Material changes
No material changes.

3) Exceptions
No exceptions.

4) Evidence
Eligible orders: 62,897.`,
    payload
  );

  assert.equal(result.ok, false);
  assert.ok(
    result.problems.some((p) =>
     p.includes('Missing required section: 5) Questions for investigation')
    )
  );
}

// 5. "9,602" matches 9602
{
  const numberPayload = {
    eligible_orders: 9602,
  };

  const result = checkAiOutput(
    `1) Executive summary
There are 9,602 eligible orders.

2) Material changes
No material changes.

3) Exceptions
No exceptions found.

4) Evidence
Eligible orders are 9602.

5) Questions for investigation
Review the result.`,
    numberPayload
  );

  assert.equal(result.ok, true);
}

// 6. Empty exceptions case passes
{
  const result = checkAiOutput(
    `1) Executive summary
Overall delay rate is 57.31%.

2) Material changes
No material changes identified.

3) Exceptions
No exceptions found.

4) Evidence
Eligible orders: 62,897.

5) Questions for investigation
Review monthly performance.`,
    payload
  );

  assert.equal(result.ok, true);
}


// 7. Invented number at end of sentence is rejected
{
  const result = checkAiOutput(fullText('The latest rate was 58.'), payload);
  assert.equal(result.ok, false);
  assert.ok(result.problems.some((p) => p.includes('Invented or unsupported number')));
}

// 8. Numbers inside payload strings are allowed
{
  const p = {
    exception_rule: 'above the overall rate and at least 500 eligible orders',
    monthly: [{ order_month: '2018-03' }],
    kpis: { eligible_orders: 62897 },
  };
  const result = checkAiOutput(
    `1) Executive summary
Month 2018-03 is covered.

2) Material changes
No material changes identified.

3) Exceptions
No exceptions found. The rule needs at least 500 eligible orders.

4) Evidence
kpis.eligible_orders: 62,897.

5) Questions for investigation
Review monthly performance.`,
    p
  );
  assert.equal(result.ok, true);
}

console.log('All AI checker tests passed.');