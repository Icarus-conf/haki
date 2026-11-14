'use client';

import { Card, Empty, Icon, PageTitle, Skeleton, useUi } from '@/components/ui';
import { fetchApi, timeAgo } from '@/lib/api';
import { useEffect, useState } from 'react';

type Entry = { id: number; adminId: number; admin: string; action: string; target: string | null; detail: string | null; createdAt: string };

const actions: Record<string, { text: string; icon: string; danger?: boolean }> = {
    'user.ban': { text: 'banned', icon: 'ban', danger: true },
    'user.unban': { text: 'unbanned', icon: 'check' },
    'lounge.delete': { text: 'deleted a Lounge message', icon: 'trash', danger: true },
    'message.delete': { text: 'deleted a reported message', icon: 'trash', danger: true },
    'report.resolved': { text: 'marked handled', icon: 'check' },
    'report.dismissed': { text: 'dismissed', icon: 'x' },
    'report.reopen': { text: 'reopened', icon: 'refresh' },
    broadcast: { text: 'sent a broadcast', icon: 'megaphone' },
    'storage.cleanup': { text: 'cleaned up storage', icon: 'database', danger: true },
    'signup.mode': { text: 'set sign-ups to', icon: 'key' },
    'invite.create': { text: 'created invite', icon: 'plus' },
    'invite.revoke': { text: 'revoked invite', icon: 'trash' },
};

export default function AuditView() {
    const { toast } = useUi();
    const [rows, setRows] = useState<Entry[] | null>(null);
    const [q, setQ] = useState('');

    useEffect(() => {
        fetchApi<Entry[]>('/admin/audit?limit=300').then(setRows).catch(e => toast(e.message, true));
    }, [toast]);

    const needle = q.trim().toLowerCase();
    const shown = (rows ?? []).filter(r => !needle || [r.admin, r.action, r.target, r.detail].some(v => v?.toLowerCase().includes(needle)));

    return (
        <>
            <PageTitle title="Audit log" subtitle="Every ban, delete, broadcast and setting change, with who did it." />
            <Card className="!p-0 overflow-hidden">
                <div className="border-b border-line p-4">
                    <label className="relative block">
                        <Icon name="search" className="absolute top-1/2 left-4 -translate-y-1/2 text-muted" />
                        <input value={q} onChange={e => setQ(e.target.value)} placeholder="Filter by admin, action or person" aria-label="Filter audit log"
                            className="w-full rounded-full border border-line bg-white/[0.04] py-2.5 pr-4 pl-11 text-sm outline-none focus:border-lime/50" />
                    </label>
                </div>
                {!rows ? <div className="space-y-2 p-4">{[...Array(6)].map((_, i) => <Skeleton key={i} className="h-12 !rounded-2xl" />)}</div>
                    : shown.length === 0 ? <Empty>{rows.length ? 'Nothing matches.' : 'No admin actions yet.'}</Empty> : (
                        <ol className="max-h-[75vh] overflow-y-auto">
                            {shown.map(r => {
                                const a = actions[r.action] ?? { text: r.action, icon: 'bolt' };
                                return (
                                    <li key={r.id} className="flex gap-3 border-b border-line/60 px-5 py-3.5 last:border-0">
                                        <span className={`mt-0.5 flex h-8 w-8 shrink-0 items-center justify-center rounded-xl ${a.danger ? 'bg-danger/15 text-danger' : 'bg-white/[0.06] text-lime'}`}>
                                            <Icon name={a.icon} size={16} />
                                        </span>
                                        <div className="min-w-0 flex-1 text-sm">
                                            <div><span className="font-medium">{r.admin}</span> <span className="text-muted">{a.text}</span> {r.target && <span className="font-medium">{r.target}</span>}</div>
                                            {r.detail && <div className="mt-0.5 truncate text-muted">“{r.detail}”</div>}
                                        </div>
                                        <time className="shrink-0 text-xs text-muted" title={new Date(r.createdAt).toLocaleString()}>{timeAgo(r.createdAt)}</time>
                                    </li>
                                );
                            })}
                        </ol>
                    )}
            </Card>
        </>
    );
}
