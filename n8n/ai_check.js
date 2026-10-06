const NUMBER_PATTERN =
  /(?<![\w.])\+?(?:\d{1,3}(?:,\d{3})+(?:\.\d+)?|\d+(?:\.\d+)?)%?(?!\w|[.,]\d)/g;

function normalizeNumber(value) {
  return Number(
    String(value)
      .replace(/,/g, "")
      .replace(/%$/, "")
      .replace(/^\+/, "")
  );
}

function collectAllowedNumbers(payload) {
  const allowed = new Set();

  function walk(value) {
    if (value === null || value === undefined) return;

    if (typeof value === "string") {
      const found = value.match(NUMBER_PATTERN);
      if (found) for (const m of found) allowed.add(normalizeNumber(m));
      return;
    }

    if (typeof value === "number" && Number.isFinite(value)) {
      allowed.add(value);
      return;
    }

    if (Array.isArray(value)) {
      for (const item of value) walk(item);
      return;
    }

    if (typeof value === "object") {
      for (const item of Object.values(value)) walk(item);
    }
  }

  walk(payload);
  return allowed;
}

function checkAiOutput(aiText, payload) {
  const problems = [];

  if (typeof aiText !== "string" || !aiText.trim()) {
    return {
      ok: false,
      problems: ["AI output is empty."]
    };
  }

  const requiredHeadings = [
    "1) Executive summary",
    "2) Material changes",
    "3) Exceptions",
    "4) Evidence",
    "5) Questions for investigation"
  ];

  for (const heading of requiredHeadings) {
    if (!aiText.includes(heading)) {
      problems.push(`Missing required section: ${heading}`);
    }
  }

  const allowedNumbers = collectAllowedNumbers(payload);

  const lines = aiText.split(/\r?\n/);

  for (const rawLine of lines) {
    const cleanedLine = rawLine.replace(/^\s*\d+[.)]\s*/, "");

    const numberMatches = cleanedLine.match(NUMBER_PATTERN);

    if (!numberMatches) continue;

    for (const match of numberMatches) {
      const numericValue = normalizeNumber(match);

      if (!allowedNumbers.has(numericValue)) {
        problems.push(`Invented or unsupported number: ${match}`);
      }
    }
  }

  const causalPatterns = [
    /\bbecause\b/i,
    /\bdue to\b/i,
    /\bcaused by\b/i,
    /\bdriven by\b/i,
    /\bas a result of\b/i,
    /\bleads to\b/i,
    /\breason is\b/i
  ];

  const sections = aiText.split(/\r?\n(?=\d+\)\s)/);

  for (const section of sections) {
    if (section.startsWith("5) Questions for investigation")) {
      continue;
    }

    for (const pattern of causalPatterns) {
      if (pattern.test(section)) {
        problems.push(
          `Unsupported causal language outside Questions section: ${pattern}`
        );
      }
    }
  }

  return {
    ok: problems.length === 0,
    problems
  };
}

module.exports = {
  checkAiOutput
};