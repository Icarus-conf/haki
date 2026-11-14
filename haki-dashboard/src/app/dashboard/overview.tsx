'use client';

import { Card, Icon, PageTitle, Skeleton, useUi } from '@/components/ui';
import { compact, fetchApi } from '@/lib/api';
import { useEffect, useState } from 'react';
import { Area, AreaChart, Bar, BarChart, Cell, Pie, PieChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts';

type Overview = {
    totals: Record<'users' | 'banned' | 'messages' | 'scheduled' | 'groups' | 'activeStories' | 'friendships' | 'pushUsers' | 'dau' | 'wau' | 'mau' | 'online' | 'calls', number>;
    daily: { date: string; messages: number; active: number }[];
    signups: { date: string; users: number }[];
    mix: { kind: string; channel: string; n: number }[];
    heatmap: { dow: number; hour: number; n: number }[];
};

const C = { lime: '#ddfb5c', violet: '#7b5cff', blue: '#2e7bff', teal: '#18b39b', pink: '#f05a9d', amber: '#ff8a3d', muted: '#8e8ea6' };
const tooltip = {
    contentStyle: { background: 'rgba(18,18,26,.92)', border: '1px solid rgba(255,255,255,.1)', borderRadius: 14, backdropFilter: 'blur(12px)', fontSize: 13 },
    labelStyle: { color: C.muted, marginBottom: 4 },
    itemStyle: { padding: 0 },
    cursor: { stroke: 'rgba(255,255,255,.15)', fill: 'rgba(255,255,255,.04)' },
};
const isoDay = (d: Date) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
const shortDay = (s: string) => new Date(`${s}T12:00:00`).toLocaleDateString(undefined, { month: 'short', day: 'numeric' });

export default function OverviewView() {
    const { toast } = useUi();
    const [data, setData] = useState<Overview | null>(null);
    const [updated, setUpdated] = useState<Date | null>(null);

    useEffect(() => {
        const tz = Intl.DateTimeFormat().resolvedOptions().timeZone;
        const load = () => fetchApi<Overview>(`/admin/overview?tz=${encodeURIComponent(tz)}`)
            .then(d => { setData(d); setUpdated(new Date()); })
            .catch(e => toast(e.message, true));
        load();
        const t = setInterval(load, 15000); // live-ish: online count and today's numbers
        return () => clearInterval(t);
    }, [toast]);

    if (!data) {
        return (
            <>
                <PageTitle title="Overview" subtitle="Loading the numbers…" />
                <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">{[...Array(4)].map((_, i) => <Skeleton key={i} className="h-36" />)}</div>
                <Skeleton className="mt-4 h-96" />
            </>
        );
    }

    const { totals: t } = data;

    // 30 local days, zeros filled in
    const byDay = new Map(data.daily.map(d => [d.date, d]));
    const signByDay = new Map(data.signups.map(d => [d.date, d.users]));
    const days = [...Array(30)].map((_, i) => {
        const d = new Date(); d.setDate(d.getDate() - 29 + i);
        const key = isoDay(d);
        return { date: key, label: shortDay(key), messages: byDay.get(key)?.messages ?? 0, active: byDay.get(key)?.active ?? 0, users: signByDay.get(key) ?? 0 };
    });
    const today = days[29], yesterday = days[28];
    const delta = yesterday.messages ? Math.round(((today.messages - yesterday.messages) / yesterday.messages) * 100) : null;
    const new7 = days.slice(-7).reduce((s, d) => s + d.users, 0);

    const channels = (['direct', 'group', 'lounge'] as const).map(c => ({ name: c, n: data.mix.filter(m => m.channel === c).reduce((s, m) => s + m.n, 0) }));
    const kinds = (['text', 'image', 'voice'] as const).map(k => ({ name: k, n: data.mix.filter(m => m.kind === k).reduce((s, m) => s + m.n, 0) }));
    const channelColor = { direct: C.violet, group: C.blue, lounge: C.lime };
    const totalMix = channels.reduce((s, c) => s + c.n, 0);
    const stickiness = t.mau ? Math.round((t.dau / t.mau) * 100) : 0;

    return (
        <>
            <PageTitle title="Overview"
                subtitle={`${new Date().toLocaleDateString(undefined, { weekday: 'long', month: 'long', day: 'numeric' })} · updated ${updated?.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' })}`}
                action={<span className="flex items-center gap-2 rounded-full border border-line bg-white/[0.04] px-3.5 py-1.5 text-sm text-muted">
                    <span className="pulse-dot h-2 w-2 rounded-full bg-lime" />Live · every 15s</span>} />

            {/* KPI bento */}
            <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
                <Card className="relative overflow-hidden !bg-lime !text-on-lime" delay={0}>
                    <div className="flex items-center justify-between text-sm font-medium opacity-70">Messages today<Icon name="chat" /></div>
                    <div className="num mt-3 text-5xl font-semibold tracking-tight">{today.messages.toLocaleString()}</div>
                    <div className="mt-2 text-sm font-medium opacity-70">
                        {delta === null ? 'No messages yesterday' : `${delta >= 0 ? '↑' : '↓'} ${Math.abs(delta)}% vs yesterday`}
                    </div>
                    <div className="pointer-events-none absolute inset-x-0 bottom-0 h-14 opacity-25">
                        <ResponsiveContainer><AreaChart data={days.slice(-14)}><Area dataKey="messages" stroke="#101300" fill="#101300" strokeWidth={2} type="monotone" isAnimationActive={false} /></AreaChart></ResponsiveContainer>
                    </div>
                </Card>
                <Kpi label="Online now" icon="bolt" value={t.online} note={`${t.users ? Math.round((t.online / t.users) * 100) : 0}% of everyone${t.calls ? ` · ${t.calls} group call${t.calls > 1 ? "s" : ""}` : ""}`} live delay={60} />
                <Kpi label="People" icon="users" value={t.users} note={`+${new7} this week · ${t.banned} banned`} delay={120} />
                <Kpi label="All messages" icon="lock" value={t.messages} note={`${compact(t.groups)} groups · ${compact(t.friendships)} friendships`} delay={180} />
            </div>

            {/* Activity + engagement */}
            <div className="mt-4 grid gap-4 xl:grid-cols-3">
                <Card title="Activity · last 30 days" className="xl:col-span-2" delay={220}
                    action={<div className="flex gap-4 text-xs text-muted">
                        <span className="flex items-center gap-1.5"><i className="h-2 w-2 rounded-full bg-violet" />Messages</span>
                        <span className="flex items-center gap-1.5"><i className="h-2 w-2 rounded-full bg-lime" />Active senders</span></div>}>
                    <div className="h-72">
                        <ResponsiveContainer>
                            <AreaChart data={days} margin={{ left: -18, right: 4, top: 8 }}>
                                <defs>
                                    <linearGradient id="gMsg" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stopColor={C.violet} stopOpacity={0.55} /><stop offset="1" stopColor={C.violet} stopOpacity={0} /></linearGradient>
                                    <linearGradient id="gAct" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stopColor={C.lime} stopOpacity={0.3} /><stop offset="1" stopColor={C.lime} stopOpacity={0} /></linearGradient>
                                </defs>
                                <XAxis dataKey="label" tick={{ fill: C.muted, fontSize: 11 }} tickLine={false} axisLine={false} interval={4} />
                                <YAxis yAxisId="m" tick={{ fill: C.muted, fontSize: 11 }} tickLine={false} axisLine={false} allowDecimals={false} />
                                <YAxis yAxisId="a" orientation="right" hide allowDecimals={false} />
                                <Tooltip {...tooltip} />
                                <Area yAxisId="m" type="monotone" dataKey="messages" name="Messages" stroke={C.violet} strokeWidth={2.5} fill="url(#gMsg)" />
                                <Area yAxisId="a" type="monotone" dataKey="active" name="Active senders" stroke={C.lime} strokeWidth={2} fill="url(#gAct)" />
                            </AreaChart>
                        </ResponsiveContainer>
                    </div>
                </Card>

                <Card title="Engagement" delay={280}>
                    <div className="flex items-center gap-5">
                        <Ring value={stickiness} />
                        <div>
                            <div className="text-sm text-muted">Stickiness</div>
                            <div className="mt-0.5 text-sm leading-snug">Of everyone active this month, <b className="text-lime">{stickiness}%</b> sent something today.</div>
                        </div>
                    </div>
                    <div className="mt-6 grid grid-cols-3 gap-2">
                        {([['Daily', t.dau], ['Weekly', t.wau], ['Monthly', t.mau]] as const).map(([l, v]) => (
                            <div key={l} className="rounded-2xl bg-white/[0.04] p-3">
                                <div className="text-xs text-muted">{l}</div>
                                <div className="num mt-1 text-2xl font-semibold">{v}</div>
                            </div>
                        ))}
                    </div>
                    <div className="mt-5 space-y-3 text-sm">
                        <Meter label="Push enabled" value={t.pushUsers} of={t.users} color={C.teal} />
                        <Meter label="Stories live now" value={t.activeStories} of={Math.max(t.users, t.activeStories)} color={C.pink} />
                        <Meter label="Scheduled, waiting" value={t.scheduled} of={Math.max(t.messages, 1)} color={C.amber} raw />
                    </div>
                </Card>
            </div>

            {/* Mix, heatmap, signups */}
            <div className="mt-4 grid gap-4 lg:grid-cols-2 xl:grid-cols-3">
                <Card title="Where people talk" delay={320}>
                    <div className="flex items-center gap-4">
                        <div className="relative h-40 w-40 shrink-0">
                            <ResponsiveContainer>
                                <PieChart>
                                    <Pie data={channels} dataKey="n" nameKey="name" innerRadius={52} outerRadius={74} paddingAngle={3} stroke="none" cornerRadius={6}>
                                        {channels.map(c => <Cell key={c.name} fill={channelColor[c.name]} />)}
                                    </Pie>
                                    <Tooltip {...tooltip} />
                                </PieChart>
                            </ResponsiveContainer>
                            <div className="pointer-events-none absolute inset-0 flex flex-col items-center justify-center">
                                <span className="num text-xl font-semibold">{compact(totalMix)}</span><span className="text-xs text-muted">messages</span>
                            </div>
                        </div>
                        <ul className="flex-1 space-y-2.5 text-sm">
                            {channels.map(c => (
                                <li key={c.name} className="flex items-center justify-between gap-2">
                                    <span className="flex items-center gap-2 capitalize"><i className="h-2.5 w-2.5 rounded-full" style={{ background: channelColor[c.name] }} />{c.name === 'direct' ? 'Direct' : c.name === 'group' ? 'Groups' : 'Lounge'}</span>
                                    <span className="num text-muted">{totalMix ? Math.round((c.n / totalMix) * 100) : 0}%</span>
                                </li>
                            ))}
                        </ul>
                    </div>
                    <div className="mt-5 flex h-2 overflow-hidden rounded-full bg-white/[0.05]">
                        {kinds.map((k, i) => <div key={k.name} style={{ width: `${totalMix ? (k.n / totalMix) * 100 : 0}%`, background: [C.violet, C.pink, C.teal][i] }} />)}
                    </div>
                    <div className="mt-2 flex justify-between text-xs text-muted">
                        {kinds.map((k, i) => <span key={k.name} className="flex items-center gap-1.5 capitalize"><i className="h-2 w-2 rounded-full" style={{ background: [C.violet, C.pink, C.teal][i] }} />{k.name} <span className="num">{compact(k.n)}</span></span>)}
                    </div>
                </Card>

                <Card title="Busiest hours · last 4 weeks" delay={360}><Heatmap cells={data.heatmap} /></Card>

                <Card title="New people · last 30 days" className="lg:col-span-2 xl:col-span-1" delay={400}
                    action={<span className="num text-sm text-muted">{days.reduce((s, d) => s + d.users, 0)} total</span>}>
                    <div className="h-48">
                        <ResponsiveContainer>
                            <BarChart data={days} margin={{ left: -24, right: 0, top: 4 }}>
                                <XAxis dataKey="label" tick={{ fill: C.muted, fontSize: 11 }} tickLine={false} axisLine={false} interval={6} />
                                <YAxis tick={{ fill: C.muted, fontSize: 11 }} tickLine={false} axisLine={false} allowDecimals={false} />
                                <Tooltip {...tooltip} />
                                <Bar dataKey="users" name="Sign-ups" radius={[6, 6, 2, 2]}>
                                    {days.map((d, i) => <Cell key={d.date} fill={i === 29 ? C.lime : 'rgba(123,92,255,.55)'} />)}
                                </Bar>
                            </BarChart>
                        </ResponsiveContainer>
                    </div>
                </Card>
            </div>
        </>
    );
}

export function Kpi({ label, icon, value, note, live, delay }: { label: string; icon: string; value: number; note: string; live?: boolean; delay: number }) {
    return (
        <Card delay={delay}>
            <div className="flex items-center justify-between text-sm text-muted">
                <span className="flex items-center gap-2">{live && <span className="pulse-dot h-2 w-2 rounded-full bg-lime" />}{label}</span>
                <Icon name={icon} className="opacity-70" />
            </div>
            <div className="num mt-3 text-5xl font-semibold tracking-tight">{value.toLocaleString()}</div>
            <div className="mt-2 text-sm text-muted">{note}</div>
        </Card>
    );
}

function Ring({ value }: { value: number }) {
    const r = 34, c = 2 * Math.PI * r;
    return (
        <svg width="88" height="88" viewBox="0 0 88 88" className="shrink-0" role="img" aria-label={`${value}% stickiness`}>
            <circle cx="44" cy="44" r={r} stroke="rgba(255,255,255,.08)" strokeWidth="9" fill="none" />
            <circle cx="44" cy="44" r={r} stroke={C.lime} strokeWidth="9" fill="none" strokeLinecap="round"
                strokeDasharray={`${(Math.min(value, 100) / 100) * c} ${c}`} transform="rotate(-90 44 44)" />
            <text x="44" y="49" textAnchor="middle" className="num" fill="#f5f5fa" fontSize="17" fontWeight="600">{value}%</text>
        </svg>
    );
}

function Meter({ label, value, of, color, raw }: { label: string; value: number; of: number; color: string; raw?: boolean }) {
    const pct = of ? Math.min(100, (value / of) * 100) : 0;
    return (
        <div>
            <div className="mb-1.5 flex justify-between"><span className="text-muted">{label}</span><span className="num">{raw ? value : `${value} / ${of}`}</span></div>
            <div className="h-1.5 rounded-full bg-white/[0.06]"><div className="h-full rounded-full" style={{ width: `${Math.max(pct, value ? 2 : 0)}%`, background: color }} /></div>
        </div>
    );
}

function Heatmap({ cells }: { cells: { dow: number; hour: number; n: number }[] }) {
    const grid = new Map(cells.map(c => [`${c.dow}-${c.hour}`, c.n]));
    const max = Math.max(1, ...cells.map(c => c.n));
    const order = [1, 2, 3, 4, 5, 6, 0]; // Mon first
    const names = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const peak = cells.reduce((p, c) => (c.n > (p?.n ?? 0) ? c : p), null as null | (typeof cells)[number]);
    return (
        <div>
            <div className="grid gap-[3px]" style={{ gridTemplateColumns: '28px repeat(24, minmax(0, 1fr))' }}>
                {order.map(d => (
                    <div key={d} className="contents">
                        <span className="text-[10px] leading-[14px] text-muted">{names[d]}</span>
                        {[...Array(24)].map((_, h) => {
                            const n = grid.get(`${d}-${h}`) ?? 0;
                            return <span key={h} title={`${names[d]} ${h}:00 · ${n} messages`} className="aspect-square rounded-[3px]"
                                style={{ background: n ? `rgba(221,251,92,${0.15 + 0.85 * Math.sqrt(n / max)})` : 'rgba(255,255,255,.05)' }} />;
                        })}
                    </div>
                ))}
            </div>
            <div className="mt-2 flex justify-between pl-[31px] text-[10px] text-muted"><span>12am</span><span>6am</span><span>12pm</span><span>6pm</span><span>11pm</span></div>
            {peak && <p className="mt-3 text-sm text-muted">Peak: <span className="text-text">{names[peak.dow]} around {peak.hour}:00</span></p>}
        </div>
    );
}
