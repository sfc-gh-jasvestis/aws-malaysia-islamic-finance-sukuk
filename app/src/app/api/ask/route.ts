import { NextResponse } from 'next/server';
import { executeQuery } from '@/lib/snowflake';
import { demoPlatform } from '@/lib/platform';

export const dynamic = 'force-dynamic';

// Only these fixed, read-only queries can run. The model never writes SQL; it
// only summarises rows returned here, so every answer is traceable to data.
const INTENTS: Record<string, { match: RegExp; sql: string }> = {
  holdings: {
    match: /escalat|holding|custodian|series|worst|highest|breach/i,
    sql: `SELECT ENTITY_ID, ENTITY_NAME, CUSTODIAN, CATEGORY, BREAK_COUNT, ESCALATED_COUNT, SLA_BREACH_COUNT, ROUND(ESCALATION_SHARE_PCT, 1) AS ESCALATION_SHARE_PCT
FROM CURATED.PERFORMANCE_SUMMARY
QUALIFY DENSE_RANK() OVER (ORDER BY ESCALATED_COUNT DESC) <= 3
ORDER BY ESCALATED_COUNT DESC, BREAK_COUNT DESC`,
  },
  types: {
    match: /type|reason|cause|why|break/i,
    sql: `SELECT BREAK_REASON, BREAK_COUNT, ESCALATED_COUNT, SLA_BREACH_COUNT, ROUND(ESCALATION_SHARE_PCT, 1) AS ESCALATION_SHARE_PCT
FROM CURATED.BREAK_SUMMARY ORDER BY ESCALATED_COUNT DESC LIMIT 8`,
  },
  kpis: {
    match: /.*/,
    sql: `SELECT TITLE, DISPLAY, SOURCE_WATERMARK FROM CURATED.KPI_SUMMARY ORDER BY SORT_ORDER`,
  },
};

const DEFINITIONS =
  'Settlement match rate = instructions processed without a settlement break / instructions processed. Escalation rate = settlement breaks escalated to custodian investigation / settlement breaks. ' +
  'A resolution SLA breach is an escalated case where the break was not resolved within the service level. Custodian system outage breaks are custodian-wide and always resolve without escalation. ' +
  'Values are in MYR; every holding is an Malaysian sukuk denominated in MYR. All data is synthetic demo data for a fictional investor. Do not give Shariah rulings, regulatory or investment advice, or price predictions.';

// provider 'cortex' = Snowflake AI_COMPLETE; 'bedrock' = Amazon Bedrock Claude
// via the external-access UDF APP.BEDROCK_GENERATE (aws/setup_aws.py).
async function summarise(question: string, rows: unknown[], provider: 'cortex' | 'bedrock' = 'cortex'): Promise<string> {
  const prompt =
    'You are a settlement analyst in the back office of a fictional Malaysian sukuk investor. Answer ONLY from the JSON rows and definitions below. ' +
    'If the rows do not answer the question, say so. Do not invent numbers. Keep it under 120 words.\n' +
    `Definitions: ${DEFINITIONS}\nRows: ${JSON.stringify(rows)}\nQuestion: ${question}`;
  const out = await executeQuery<{ R: string }>(
    provider === 'bedrock' ? 'SELECT APP.BEDROCK_GENERATE(?) AS R' : `SELECT AI_COMPLETE('claude-sonnet-4-5', ?) AS R`,
    [prompt],
  );
  const raw = String(out[0]?.R ?? '').trim();
  // AI_COMPLETE returns a JSON string literal; decode it when present.
  try {
    const parsed = JSON.parse(raw);
    return typeof parsed === 'string' ? parsed : raw;
  } catch {
    return raw;
  }
}

export async function POST(req: Request) {
  let body: any;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: 'Invalid JSON' }, { status: 400 });
  }
  const question = typeof body?.question === 'string' ? body.question.trim().slice(0, 2000) : '';
  const memo = body?.mode === 'memo';
  if (!memo && !question) return NextResponse.json({ error: 'Question required' }, { status: 400 });

  try {
    if (memo) {
      const provider = demoPlatform() === 'aws' ? 'bedrock' : 'cortex';
      const [kpis, routes, types, risk, bands] = await Promise.all([
        executeQuery(INTENTS.kpis.sql),
        executeQuery(INTENTS.holdings.sql),
        executeQuery(INTENTS.types.sql),
        executeQuery(`SELECT ENTITY_ID, ROUND(ESCALATION_PROB_7D, 2) AS ESCALATION_PROB_7D, RISK_BAND
FROM ML.ESCALATION_RISK_SCORES ORDER BY ESCALATION_PROB_7D DESC LIMIT 5`),
        executeQuery(`SELECT RISK_BAND, COUNT(*) AS HOLDINGS FROM ML.ESCALATION_RISK_SCORES GROUP BY RISK_BAND`),
      ]);
      const rows = { kpis, topEscalatedHoldings: routes, breakReasons: types, top5ByRisk: risk, holdingsPerRiskBand: bands };
      const answer = await summarise(
        'Draft a short action memo for the Head of Sukuk Operations with 3 prioritised operational actions, citing the figures. Do not give investment advice.',
        [rows],
        provider,
      );
      return NextResponse.json({ answer, sources: rows, provider: provider === 'bedrock' ? 'Amazon Bedrock (Claude Sonnet 4.5)' : 'Snowflake Cortex AI_COMPLETE (claude-sonnet-4-5)', draft: true, synthetic: true });
    }
    const key = Object.keys(INTENTS).find((k) => INTENTS[k].match.test(question))!;
    const rows = await executeQuery(INTENTS[key].sql);
    const answer = await summarise(question, rows);
    return NextResponse.json({ answer, sql: INTENTS[key].sql, sources: rows, synthetic: true });
  } catch (err) {
    console.error('ask route failed', err);
    return NextResponse.json({ error: 'AI service unavailable' }, { status: 503 });
  }
}
