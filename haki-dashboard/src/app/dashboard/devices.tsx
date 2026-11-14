'use client';

import { Badge, Card, Empty, Icon, PageTitle, Skeleton, useUi } from '@/components/ui';
import { fetchApi, timeAgo } from '@/lib/api';
import { useEffect, useState } from 'react';
import { Bar, BarChart, Cell, Pie, PieChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts';
import { Kpi } from './overview';

type Platform = { platform: string; active: number; seen7d: number; linked: number; online: number };
type Devices = {
    totals: { active: number; linked: number; removed30d: number; users: number; online: number };
    platforms: Platform[];
    daily: { day: string; logins: number; links: number }[];
    multi: { devices: number; users: number }[];
    push: { platform: string; count: number }[];
    recent: { id: string; username: string; name: string; platform: string; kind: string; createdAt: string; lastSeenAt: string; revokedAt: string | null; online: boolean }[];
};

const C = { lime: '#ddfb5c', violet: '#7b5cff', blue: '#2e7bff', teal: '#18b39b', pink: '#f05a9d', amber: '#ff8a3d', muted: '#8e8ea6' };
const look: Record<string, { label: string; color: string; icon: string }> = {
    ios: { label: 'iPhone & iPad', color: C.violet, icon: 'phone' },
    android: { label: 'Android', color: C.teal, icon: 'phone' },
    macos: { label: 'Mac', color: C.lime, icon: 'laptop' },
    windows: { label: 'Windows', color: C.blue, icon: 'laptop' },
    linux: { label: 'Linux', color: C.amber, icon: 'laptop' },
    web: { label: 'Web browser', color: C.pink, icon: 'globe' },
    voip: { label: 'iPhone calls (VoIP)', color: C.blue, icon: 'phone' },
};
const of = (p: string) => look[p] ?? { label: p, color: C.muted, icon: 'laptop' };
const tooltip = {
    contentStyle: { background: 'rgba(18,18,26,.92)', border: '1px solid rgba(255,255,255,.1)', borderRadius: 14, fontSize: 13 },
    labelStyle: { color: C.muted, marginBottom: 4 },
    cursor: { fill: 'rgba(255,255,255,.04)' },
};
const shortDay = (s: string) => new Date(`${s}T12:00:00`).toLocaleDateString(undefined, { month: 'short', day: 'numeric' });

export default function DevicesView() {
    const { toast } = useUi();
    const [d, setD] = useState<Devices | null>(null);

    useEffect(() => {
        const load = () => fetchApi<Devices>('/admin/devices').then(setD).catch(e => toast(e.message, true));
        load();
        const t = setInterval(load, 15000);
        return () => clearInterval(t);
    }, [toast]);

    if (!d) {
        return (
            <>
                <PageTitle title="Devices" subtitle="Loading…" />
                <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">{[...Array(4)].map((_, i) => <Skeleton key={i} className="h-36" />)}</div>
                <Skeleton className="mt-4 h-80" />
            </>
        );
    }

    const t = d.totals;
    const phones = d.platforms.filter(p => p.platform === 'ios' || p.platform === 'android').reduce((s, p) => s + p.active, 0);
    const computers = t.active - phones;
    const multiUsers = d.multi.filter(m => m.devices >= 2).reduce((s, m) => s + m.users, 0);
    const days = d.daily.map(x => ({ ...x, label: shortDay(x.day) }));
    const new14 = d.daily.reduce((s, x) => s + x.logins + x.links, 0);

    return (
        <>
            <PageTitle title="Devices" subtitle="Phones, computers and browsers signed in to Haki. Counts only; no message content."
                action={<span className="flex items-center gap-2 rounded-full border border-line bg-white/[0.04] px-3.5 py-1.5 text-sm text-muted">
                    <span className="pulse-dot h-2 w-2 rounded-full bg-lime" />Live · every 15s</span>} />

            <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
                <Kpi label="Signed-in devices" icon="laptop" value={t.active} note={`${t.users.toLocaleString()} people · ${phones} phones, ${computers} computers & browsers`} delay={0} />
                <Kpi label="Connected now" icon="bolt" value={t.online} note={`${t.active ? Math.round((t.online / t.active) * 100) : 0}% of signed-in devices`} live delay={60} />
                <Kpi label="Linked from a phone" icon="link" value={t.linked} note={`${t.active ? Math.round((t.linked / t.active) * 100) : 0}% added by scanning a code`} delay={120} />
                <Kpi label="On 2+ devices" icon="users" value={multiUsers} note={`${t.users ? Math.round((multiUsers / t.users) * 100) : 0}% of people · ${t.removed30d} removed in 30 days`} delay={180} />
            </div>

            <div className="mt-4 grid gap-4 xl:grid-cols-3">
                <Card title="By platform" delay={220}>
                    {d.platforms.length === 0 ? <Empty>No devices yet.</Empty> : (
                        <>
                            <div className="relative mx-auto h-44 w-44">
                                <ResponsiveContainer>
                                    <PieChart>
                                        <Pie data={d.platforms} dataKey="active" nameKey="platform" innerRadius={56} outerRadius={80} paddingAngle={3} stroke="none">
                                            {d.platforms.map(p => <Cell key={p.platform} fill={of(p.platform).color} />)}
                                        </Pie>
                                    </PieChart>
                                </ResponsiveContainer>
                                <div className="pointer-events-none absolute inset-0 grid place-items-center text-center">
                                    <div><div className="num text-3xl font-semibold">{t.active}</div><div className="text-xs text-muted">devices</div></div>
                                </div>
                            </div>
                            <ul className="mt-4 space-y-3">
                                {d.platforms.map(p => (
                                    <li key={p.platform} className="flex items-center gap-3 text-sm">
                                        <span className="grid h-8 w-8 place-items-center rounded-xl" style={{ background: `${of(p.platform).color}22`, color: of(p.platform).color }}>
                                            <Icon name={of(p.platform).icon} size={16} />
                                        </span>
                                        <span className="flex-1">{of(p.platform).label}</span>
                                        <span className="text-xs text-muted">{p.online} online · {p.seen7d} this week</span>
                                        <span className="num w-8 text-right font-medium">{p.active}</span>
                                    </li>
                                ))}
                            </ul>
                        </>
                    )}
                </Card>

                <Card title="New devices · last 14 days" className="xl:col-span-2" delay={280}
                    action={<div className="flex gap-4 text-xs text-muted">
                        <span className="flex items-center gap-1.5"><i className="h-2 w-2 rounded-full bg-violet" />Signed in</span>
                        <span className="flex items-center gap-1.5"><i className="h-2 w-2 rounded-full bg-lime" />Linked from a phone</span>
                        <span>{new14} total</span></div>}>
                    <div className="h-72">
                        <ResponsiveContainer>
                            <BarChart data={days} margin={{ left: -18, right: 4, top: 8 }}>
                                <XAxis dataKey="label" tick={{ fill: C.muted, fontSize: 11 }} tickLine={false} axisLine={false} interval={1} />
                                <YAxis tick={{ fill: C.muted, fontSize: 11 }} tickLine={false} axisLine={false} allowDecimals={false} />
                                <Tooltip {...tooltip} />
                                <Bar dataKey="logins" name="Signed in" stackId="a" fill={C.violet} />
                                <Bar dataKey="links" name="Linked" stackId="a" fill={C.lime} radius={[6, 6, 0, 0]} />
                            </BarChart>
                        </ResponsiveContainer>
                    </div>
                </Card>
            </div>

            <div className="mt-4 grid gap-4 xl:grid-cols-3">
                <Card title="Devices per person" delay={320}>
                    <div className="space-y-3">
                        {[1, 2, 3, 4].map(n => {
                            const users = d.multi.find(m => m.devices === n)?.users ?? 0;
                            const pct = t.users ? (users / t.users) * 100 : 0;
                            return (
                                <div key={n}>
                                    <div className="mb-1 flex justify-between text-sm"><span>{n === 4 ? '4 or more' : `${n} device${n > 1 ? 's' : ''}`}</span><span className="num text-muted">{users}</span></div>
                                    <div className="h-2 overflow-hidden rounded-full bg-white/[0.06]"><div className="h-full rounded-full bg-lime" style={{ width: `${pct}%` }} /></div>
                                </div>
                            );
                        })}
                    </div>
                    <div className="mt-6 border-t border-line pt-4">
                        <div className="mb-2 text-sm text-muted">Can get notifications</div>
                        {d.push.length === 0 ? <div className="text-sm text-muted">None yet.</div> : (
                            <div className="flex flex-wrap gap-2">
                                {d.push.map(p => <Badge key={p.platform} tone="muted">{of(p.platform).label} · {p.count}</Badge>)}
                            </div>
                        )}
                    </div>
                </Card>

                <Card title="Recent activity" className="overflow-hidden xl:col-span-2" delay={360}>
                    {d.recent.length === 0 ? <Empty>No devices yet.</Empty> : (
                        <div className="-mx-5 -mb-5 overflow-x-auto border-t border-line">
                            <table className="w-full text-sm">
                                <thead className="text-left text-xs text-muted">
                                    <tr className="border-b border-line">
                                        <th className="px-5 py-3 font-medium">Device</th><th className="px-3 py-3 font-medium">Person</th>
                                        <th className="px-3 py-3 font-medium">How</th><th className="px-3 py-3 font-medium">Last seen</th><th className="px-3 py-3 font-medium">State</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {d.recent.map(r => (
                                        <tr key={r.id} className="border-b border-line/60 last:border-0">
                                            <td className="px-5 py-3">
                                                <div className="flex items-center gap-2.5">
                                                    <span style={{ color: of(r.platform).color }}><Icon name={of(r.platform).icon} size={16} /></span>
                                                    <div><div className="font-medium">{r.name}</div><div className="text-xs text-muted">{of(r.platform).label}</div></div>
                                                </div>
                                            </td>
                                            <td className="px-3 py-3">@{r.username}</td>
                                            <td className="px-3 py-3 text-muted">{r.kind === 'linked' ? 'Linked' : 'Signed in'} · {timeAgo(r.createdAt)}</td>
                                            <td className="px-3 py-3 text-muted">{r.online ? 'now' : timeAgo(r.lastSeenAt)}</td>
                                            <td className="px-3 py-3">
                                                {r.revokedAt ? <Badge tone="danger">removed</Badge> : r.online ? <Badge tone="lime">online</Badge> : <Badge tone="muted">signed in</Badge>}
                                            </td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                    )}
                </Card>
            </div>
        </>
    );
}
