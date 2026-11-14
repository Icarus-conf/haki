'use client';

import { Card, Empty, PageTitle, Skeleton, useUi } from '@/components/ui';
import { fetchApi } from '@/lib/api';
import { useEffect, useState } from 'react';
import { Bar, BarChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts';
import { Kpi } from './overview';

type FeedStats = {
    totals: { posts: number; posts7d: number; comments: number; reactions: number; posters7d: number; media: number; avgReaders: number | null };
    daily: { day: string; posts: number; comments: number; reactions: number }[];
    top: { username: string; posts: number; comments: number }[];
};

const C = { lime: '#ddfb5c', violet: '#7b5cff', teal: '#18b39b', muted: '#8e8ea6' };
const tooltip = {
    contentStyle: { background: 'rgba(18,18,26,.92)', border: '1px solid rgba(255,255,255,.1)', borderRadius: 14, fontSize: 13 },
    labelStyle: { color: C.muted, marginBottom: 4 },
    cursor: { fill: 'rgba(255,255,255,.04)' },
};
const shortDay = (s: string) => new Date(`${s}T12:00:00`).toLocaleDateString(undefined, { month: 'short', day: 'numeric' });

/** Feed activity. Posts and comments are end-to-end encrypted, so this is counts only. */
export default function FeedView() {
    const { toast } = useUi();
    const [d, setD] = useState<FeedStats | null>(null);

    useEffect(() => {
        const load = () => fetchApi<FeedStats>('/admin/feed').then(setD).catch(e => toast(e.message, true));
        load();
        const t = setInterval(load, 30000);
        return () => clearInterval(t);
    }, [toast]);

    if (!d) {
        return (
            <>
                <PageTitle title="Feed" subtitle="Loading…" />
                <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">{[...Array(4)].map((_, i) => <Skeleton key={i} className="h-36" />)}</div>
                <Skeleton className="mt-4 h-80" />
            </>
        );
    }

    const t = d.totals;
    const days = d.daily.map(x => ({ ...x, label: shortDay(x.day) }));
    const per = (n: number) => (t.posts ? (n / t.posts).toFixed(1) : '0');

    return (
        <>
            <PageTitle title="Feed" subtitle="Friends' posts, comments and reactions. Content is end-to-end encrypted: these are counts only." />

            <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
                <Kpi label="Posts" icon="feed" value={t.posts} note={`${t.posts7d} this week · ${t.media} photos & videos`} delay={0} />
                <Kpi label="Posting this week" icon="users" value={t.posters7d} note="people who posted in 7 days" delay={60} />
                <Kpi label="Comments" icon="chat" value={t.comments} note={`${per(t.comments)} per post`} delay={120} />
                <Kpi label="Reactions" icon="heart" value={t.reactions} note={`${per(t.reactions)} per post · ${t.avgReaders ?? 0} readers per post`} delay={180} />
            </div>

            <div className="mt-4 grid gap-4 xl:grid-cols-3">
                <Card title="Last 14 days" className="xl:col-span-2" delay={220}
                    action={<div className="flex gap-4 text-xs text-muted">
                        <span className="flex items-center gap-1.5"><i className="h-2 w-2 rounded-full bg-lime" />Posts</span>
                        <span className="flex items-center gap-1.5"><i className="h-2 w-2 rounded-full bg-violet" />Comments</span>
                        <span className="flex items-center gap-1.5"><i className="h-2 w-2 rounded-full" style={{ background: C.teal }} />Reactions</span></div>}>
                    <div className="h-72">
                        <ResponsiveContainer>
                            <BarChart data={days} margin={{ left: -18, right: 4, top: 8 }}>
                                <XAxis dataKey="label" tick={{ fill: C.muted, fontSize: 11 }} tickLine={false} axisLine={false} interval={1} />
                                <YAxis tick={{ fill: C.muted, fontSize: 11 }} tickLine={false} axisLine={false} allowDecimals={false} />
                                <Tooltip {...tooltip} />
                                <Bar dataKey="posts" name="Posts" fill={C.lime} radius={[5, 5, 0, 0]} />
                                <Bar dataKey="comments" name="Comments" fill={C.violet} radius={[5, 5, 0, 0]} />
                                <Bar dataKey="reactions" name="Reactions" fill={C.teal} radius={[5, 5, 0, 0]} />
                            </BarChart>
                        </ResponsiveContainer>
                    </div>
                </Card>

                <Card title="Most active · 30 days" delay={280}>
                    {d.top.length === 0 ? <Empty>No posts yet.</Empty> : (
                        <ul className="space-y-3">
                            {d.top.map((u, i) => (
                                <li key={u.username} className="flex items-center gap-3 text-sm">
                                    <span className="num w-5 text-muted">{i + 1}</span>
                                    <span className="flex-1 truncate">@{u.username}</span>
                                    <span className="text-xs text-muted">{u.comments} comments</span>
                                    <span className="num w-10 text-right font-medium">{u.posts}</span>
                                </li>
                            ))}
                        </ul>
                    )}
                </Card>
            </div>
        </>
    );
}
