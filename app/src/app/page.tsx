'use client';

import { useEffect, useState } from 'react';
import { AppLayout } from '@/components/AppLayout';
import { KPICard } from '@/components/KPICard';
import { Chart } from '@/components/Chart';
import { DataTable } from '@/components/DataTable';
import { AskAI } from '@/components/AskAI';
import { ActionMemo } from '@/components/ActionMemo';
import { GeoMap } from '@/components/GeoMap';

interface DemoNarrative {
  title: string;
  duration: string;
  thesis: string;
  tabs: any[];
}

export default function HomePage() {
  const [narrative, setNarrative] = useState<DemoNarrative | null>(null);
  const [data, setData] = useState<any>(null);

  useEffect(() => {
    fetch('/demo_narrative.json')
      .then((r) => r.json())
      .then(setNarrative)
      .catch(() => {});
    fetch('/api/data')
      .then((r) => r.json())
      .then(setData)
      .catch(() => {});
  }, []);

  const title = narrative?.title || 'SEA AWS Demo';

  const executiveCockpit = (
    <div className="space-y-6">
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <KPICard title="Outstanding Sukuk" value="RM 1.2T" status="neutral" />
        <KPICard title="New Issuance (YTD)" value="RM 184B" status="neutral" />
        <KPICard title="Avg Yield" value="3.8%" status="neutral" />
        <KPICard title="Active Issuers" value="84" status="neutral" />
      </div>
      <div className="grid grid-cols-1 gap-4 lg:grid-cols-3">
        <div className="lg:col-span-1">
          <GeoMap
            country="malaysia"
            markers={[{"label": "Kuala Lumpur", "value": "Islamic finance hub", "color": "blue", "size": "lg"}, {"label": "Penang", "value": "Regional branch", "color": "green", "size": "md"}, {"label": "Johor Bahru", "value": "Southern ops", "color": "green", "size": "md"}, {"label": "Kota Kinabalu", "value": "E.Malaysia branch", "color": "green", "size": "sm"}]}
            routes={[]}
            title="Geographic Overview"
            height={280}
          />
        </div>
        <div className="lg:col-span-2 grid grid-cols-1 gap-4">
      <div className="grid grid-cols-1 gap-4 grid-cols-1">
        <Chart data={data?.timeseries || [{ period: 'Loading', value: 0 }]} type="line" xKey="period" yKeys={[{ key: 'value', name: 'RM B' }]} title="Sukuk Issuance Volume (Monthly)" />
        <Chart data={data?.categories || [{ category: 'Loading', count: 0 }]} type="bar" xKey="category" yKeys={[{ key: 'count', name: 'RM B' }]} title="Outstanding by Structure" />
      </div>
        </div>
      </div>
      <DataTable columns={[
          { key: 'id', header: '#' },
          { key: 'name', header: 'Issuer' },
          { key: 'status', header: 'Rating' },
          { key: 'value', header: 'Amount (RM B)' },
      ]} data={data?.entities || []} title="Recent Sukuk Issuances" />
    </div>
  );

  const domainTab1 = (
    <div className="space-y-6">
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <KPICard title="Foreign Holdings" value="24%" />
        <KPICard title="Avg Tenor" value="5.4 yrs" />
        <KPICard title="Spread vs MGS" value="+42 bps" />
      </div>
      <Chart data={data?.detail || [{ x: 'Loading', y: 0 }]} type="area" xKey="x" yKeys={[{ key: 'y', name: 'Yield %' }]} title="Sukuk Yield Curve" height={400} />
    </div>
  );

  const domainTab2 = (
    <div className="space-y-6">
      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        <Chart data={data?.breakdown || [{ label: 'A', value: 30 }, { label: 'B', value: 70 }]} type="pie" xKey="label" yKeys={[{ key: 'value', name: 'RM B' }]} title="Upcoming Issuances" />
        <ActionMemo persona={{ name: 'Dato' Zainal Izlan', role: 'Head of Islamic Capital Markets' }} context={{}} onGenerate={async () => ({ subject: 'Action Required', body: 'AI-generated recommendation based on current data patterns.', urgency: 'HIGH', actions: ['Prepare GII pricing', 'Review PLUS sustainability sukuk', 'Update SC ESG sukuk reporting'] })} />
      </div>
    </div>
  );

  const askAiTab = (
    <div className="h-[600px]">
      <AskAI title="Ask AI" mode="both" sampleQuestions={['What is the sukuk yield spread vs MGS?', 'Show foreign holdings trend', 'Which issuances are in pipeline?']} onSubmit={async (question, mode) => ({ answer: `[Demo Mode] Response to: "${question}" (${mode} mode). Connect to Snowflake for live data.`, sql: mode === 'sql' ? 'SELECT * FROM CURATED.SUMMARY LIMIT 10;' : undefined })} />
    </div>
  );

  const architectureTab = (
    <div className="space-y-6">
      <div className="rounded-lg border border-slate-200 bg-white p-6">
        <h2 className="mb-4 text-lg font-bold text-slate-900">Architecture</h2>
        <p className="mb-4 text-sm text-slate-600">This demo runs on Snowflake with optional AWS integration.</p>
        <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
          <div className="rounded border border-blue-200 bg-blue-50 p-4">
            <h3 className="text-sm font-bold text-blue-800">Snowflake Features</h3>
            <ul className="mt-2 space-y-1 text-sm text-blue-700">
              <li>• Dynamic Tables (5-min refresh)</li>
              <li>• ML Functions (Forecast + Anomaly)</li>
              <li>• Cortex Search + Agent</li>
              <li>• Semantic View + Intelligence</li>
              <li>• Alerts + Notifications</li>
            </ul>
          </div>
          <div className="rounded border border-orange-200 bg-orange-50 p-4">
            <h3 className="text-sm font-bold text-orange-800">AWS Services</h3>
            <ul className="mt-2 space-y-1 text-sm text-orange-700">
              <li>• Amazon S3 (Strategy Docs)</li>
              <li>• Amazon S3 + Kinesis</li>
              <li>• Amazon SNS</li>
              <li>• Amazon QuickSight + Q</li>
            </ul>
          </div>
        </div>
      </div>
      <div className="rounded-lg border border-slate-200 bg-white p-6">
        <h2 className="mb-2 text-lg font-bold text-slate-900">Build Modes</h2>
        <div className="grid grid-cols-2 gap-4">
          <div className="rounded border border-emerald-200 bg-emerald-50 p-3">
            <h4 className="text-sm font-bold text-emerald-800">Snowflake Only</h4>
            <p className="mt-1 text-xs text-emerald-700">All features run natively in Snowflake. No AWS dependencies.</p>
          </div>
          <div className="rounded border border-violet-200 bg-violet-50 p-3">
            <h4 className="text-sm font-bold text-violet-800">Full AWS + Snowflake</h4>
            <p className="mt-1 text-xs text-violet-700">S3, Kinesis, SNS, QuickSight integrated with Snowflake Cortex AI.</p>
          </div>
        </div>
      </div>
    </div>
  );

  const tabs = [
    { id: 'executive-cockpit', label: 'Executive Cockpit', icon: '📊', content: executiveCockpit },
    { id: 'domain-1', label: 'Market Analytics', icon: '📈', content: domainTab1 },
    { id: 'domain-2', label: 'Pipeline', icon: '⚡', content: domainTab2 },
    { id: 'ask-ai', label: 'Ask AI', icon: '🤖', content: askAiTab },
    { id: 'architecture', label: 'Architecture & Data', icon: '🏗️', content: architectureTab },
  ];

  return <AppLayout title={title} subtitle="Powered by Snowflake + AWS" tabs={tabs} narrative={narrative} />;
}
