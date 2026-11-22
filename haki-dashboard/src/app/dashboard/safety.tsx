'use client';

import { Avatar, Badge, Button, Card, Empty, Icon, PageTitle, Skeleton, useUi } from '@/components/ui';
import { fetchApi, timeAgo } from '@/lib/api';
import { useEffect, useState } from 'react';

type Signal = { kind: string; label: string; value: number };
type Row = { id: number; username: string; displayName: string | null; avatarUrl: string | null; isBanned: boolean; createdAt: string; signals: Signal[]; score: number };

const kinds: Record<string, { name: string; icon: string }> = {
    burst: { name: 'Bursts', icon: 'bolt' },
    ratelimit: { name: 'Send limit', icon: 'pause' },
    requests: { name: 'Friend requests', icon: 'users' },
    new: { name: 'New account', icon: 'refresh' },
    reports: { name: 'Reports', icon: 'flag' },
};

export default function SafetyView() {
    const { toast, confirm } = useUi();
    const [rows, setRows] = useState<Row[] | null>(null);

    useEffect(() => {
        const load = () => fetchApi<Row[]>('/admin/signals').then(setRows).catch(e => toast(e.message, true));
        load();
        const t = setInterval(load, 30000);
        return () => clearInterval(t);
    }, [toast]);

    const ban = async (r: Row) => {
        if (!(await confirm({ title: `Ban ${r.displayName || r.username}?`, body: 'They are signed out everywhere right away.', confirm: 'Ban', danger: true }))) return;
        try {
            await fetchApi(`/admin/users/${r.id}/ban`, { method: 'PATCH' });
            setRows(list => list!.map(x => x.id === r.id ? { ...x, isBanned: true } : x));
            toast(`${r.username} banned`);
        } catch (e: any) { toast(e.message, true); }
    };

    return (
        <>
            <PageTitle title="Spam signals" subtitle="Accounts acting like bots, from counts and timestamps only. No message is read to make this list." />
            <div className="grid gap-4 xl:grid-cols-[1fr_320px]">
                <div>
                    {!rows ? <div className="space-y-3">{[...Array(3)].map((_, i) => <Skeleton key={i} className="h-28" />)}</div>
                        : rows.length === 0 ? <Card><Empty>Nobody looks suspicious right now.</Empty></Card> : (
                            <div className="space-y-3">
                                {rows.map((r, i) => (
                                    <Card key={r.id} delay={i * 40}>
                                        <div className="flex flex-wrap items-start gap-3">
                                            <Avatar id={r.id} name={r.displayName || r.username} url={r.avatarUrl} size={42} />
                                            <div className="min-w-0 flex-1">
                                                <div className="flex flex-wrap items-center gap-2">
                                                    <span className="font-medium">{r.displayName || r.username}</span>
                                                    <span className="text-sm text-muted">@{r.username}</span>
                                                    {r.isBanned && <Badge tone="danger">banned</Badge>}
                                                </div>
                                                <div className="mt-0.5 text-xs text-muted">Joined {timeAgo(r.createdAt)}</div>
                                                <div className="mt-3 flex flex-wrap gap-2">
                                                    {r.signals.map(s => (
                                                        <span key={s.kind} className="inline-flex items-center gap-1.5 rounded-full border border-line bg-white/[0.04] px-3 py-1 text-sm">
                                                            <Icon name={kinds[s.kind]?.icon ?? 'flag'} size={14} className="text-lime" />{s.label}
                                                        </span>
                                                    ))}
                                                </div>
                                            </div>
                                            <div className="flex items-center gap-3">
                                                <div className="text-right">
                                                    <div className={`num text-3xl font-semibold ${r.score >= 5 ? 'text-danger' : ''}`}>{r.score}</div>
                                                    <div className="text-xs text-muted">score</div>
                                                </div>
                                                {!r.isBanned && <Button kind="danger" icon="ban" onClick={() => ban(r)}>Ban</Button>}
                                            </div>
                                        </div>
                                    </Card>
                                ))}
                            </div>
                        )}
                </div>
                <Card title="What raises a flag">
                    <ul className="space-y-3 text-sm text-muted">
                        <li className="flex gap-2"><Icon name="bolt" size={16} className="mt-0.5 shrink-0 text-lime" />15+ messages in a single minute (last 24 hours).</li>
                        <li className="flex gap-2"><Icon name="pause" size={16} className="mt-0.5 shrink-0 text-lime" />Hit the send limit: 30 messages per 10 seconds. Extra messages are refused.</li>
                        <li className="flex gap-2"><Icon name="users" size={16} className="mt-0.5 shrink-0 text-lime" />10+ friend requests in a day.</li>
                        <li className="flex gap-2"><Icon name="refresh" size={16} className="mt-0.5 shrink-0 text-lime" />Account under 2 days old with 50+ messages.</li>
                        <li className="flex gap-2"><Icon name="flag" size={16} className="mt-0.5 shrink-0 text-lime" />2+ open reports against them (weighs most).</li>
                    </ul>
                </Card>
            </div>
        </>
    );
}
