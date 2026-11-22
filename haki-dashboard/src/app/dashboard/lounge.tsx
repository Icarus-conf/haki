'use client';

import { Avatar, Badge, Card, Empty, Icon, PageTitle, Skeleton, useUi } from '@/components/ui';
import { fetchApi, timeAgo } from '@/lib/api';
import { useEffect, useState } from 'react';

type Msg = { id: number; content: string; createdAt: string; attachmentType: string | null; senderId: number; username: string; displayName: string | null; isBanned: boolean };

export default function LoungeView() {
    const { toast, confirm } = useUi();
    const [msgs, setMsgs] = useState<Msg[] | null>(null);
    const [q, setQ] = useState('');

    useEffect(() => {
        const load = () => fetchApi<Msg[]>('/admin/lounge?limit=100').then(setMsgs).catch(e => toast(e.message, true));
        load();
        const t = setInterval(load, 10000);
        return () => clearInterval(t);
    }, [toast]);

    const remove = async (m: Msg) => {
        if (!(await confirm({ title: 'Delete this message?', body: `“${m.content.slice(0, 120)}” disappears from the Lounge for everyone.`, confirm: 'Delete', danger: true }))) return;
        try {
            await fetchApi(`/admin/lounge/${m.id}`, { method: 'DELETE' });
            setMsgs(list => list!.filter(x => x.id !== m.id));
            toast('Message removed');
        } catch (e: any) { toast(e.message, true); }
    };

    const ban = async (m: Msg) => {
        if (!(await confirm({ title: `Ban ${m.username}?`, body: 'They are signed out everywhere right away.', confirm: 'Ban', danger: true }))) return;
        try {
            await fetchApi(`/admin/users/${m.senderId}/ban`, { method: 'PATCH' });
            setMsgs(list => list!.map(x => x.senderId === m.senderId ? { ...x, isBanned: true } : x));
            toast(`${m.username} banned`);
        } catch (e: any) { toast(e.message, true); }
    };

    const needle = q.trim().toLowerCase();
    const shown = (msgs ?? []).filter(m => !needle || m.content.toLowerCase().includes(needle) || m.username.toLowerCase().includes(needle));

    return (
        <>
            <PageTitle title="Lounge" subtitle="The public room. The only chat you can read, so it’s the only one you moderate." />
            <div className="grid gap-4 xl:grid-cols-[1fr_320px]">
                <Card className="!p-0 overflow-hidden">
                    <div className="border-b border-line p-4">
                        <label className="relative block">
                            <Icon name="search" className="absolute top-1/2 left-4 -translate-y-1/2 text-muted" />
                            <input value={q} onChange={e => setQ(e.target.value)} placeholder="Filter messages or people" aria-label="Filter Lounge"
                                className="w-full rounded-full border border-line bg-white/[0.04] py-2.5 pr-4 pl-11 text-sm outline-none focus:border-lime/50" />
                        </label>
                    </div>
                    {!msgs ? <div className="space-y-2 p-4">{[...Array(5)].map((_, i) => <Skeleton key={i} className="h-16 !rounded-2xl" />)}</div>
                        : shown.length === 0 ? <Empty>{msgs.length ? 'Nothing matches.' : 'The Lounge is quiet.'}</Empty> : (
                            <ul className="max-h-[70vh] overflow-y-auto">
                                {shown.map(m => (
                                    <li key={m.id} className="group flex gap-3 border-b border-line/60 px-5 py-4 last:border-0 hover:bg-white/[0.03]">
                                        <Avatar id={m.senderId} name={m.displayName || m.username} size={38} />
                                        <div className="min-w-0 flex-1">
                                            <div className="flex flex-wrap items-center gap-2 text-sm">
                                                <span className="font-medium">{m.displayName || m.username}</span>
                                                <span className="text-muted">@{m.username}</span>
                                                {m.isBanned && <Badge tone="danger">banned</Badge>}
                                                <span className="text-xs text-muted" title={new Date(m.createdAt).toLocaleString()}>· {timeAgo(m.createdAt)}</span>
                                            </div>
                                            <p className="mt-1 break-words whitespace-pre-wrap text-[15px] leading-relaxed">
                                                {m.attachmentType ? <span className="text-muted italic">[{m.attachmentType}]</span> : highlight(m.content)}
                                            </p>
                                        </div>
                                        <div className="flex shrink-0 items-start gap-1 opacity-100 transition sm:opacity-0 sm:group-focus-within:opacity-100 sm:group-hover:opacity-100">
                                            <button onClick={() => remove(m)} title="Delete message" aria-label="Delete message" className="rounded-full p-2 text-muted hover:bg-danger/15 hover:text-danger"><Icon name="trash" size={17} /></button>
                                            {!m.isBanned && <button onClick={() => ban(m)} title={`Ban ${m.username}`} aria-label={`Ban ${m.username}`} className="rounded-full p-2 text-muted hover:bg-danger/15 hover:text-danger"><Icon name="ban" size={17} /></button>}
                                        </div>
                                    </li>
                                ))}
                            </ul>
                        )}
                </Card>

                <div className="space-y-4">
                    <Card title="Last 100 messages">
                        <div className="num text-4xl font-semibold">{msgs ? new Set(msgs.map(m => m.senderId)).size : '–'}</div>
                        <div className="mt-1 text-sm text-muted">different people talking</div>
                        {msgs?.[0] && <div className="mt-4 text-sm text-muted">Latest {timeAgo(msgs[0].createdAt)}</div>}
                    </Card>
                    <Card title="Good to know">
                        <ul className="space-y-3 text-sm text-muted">
                            <li className="flex gap-2"><Icon name="trash" size={16} className="mt-0.5 shrink-0 text-lime" />Deleting removes it live from every open app.</li>
                            <li className="flex gap-2"><Icon name="ban" size={16} className="mt-0.5 shrink-0 text-lime" />Banning signs the person out on all devices.</li>
                            <li className="flex gap-2"><Icon name="lock" size={16} className="mt-0.5 shrink-0 text-lime" />Direct and group chats are end-to-end encrypted. They never appear here.</li>
                        </ul>
                    </Card>
                </div>
            </div>
        </>
    );
}

const highlight = (text: string) => text.split(/(@\w+)/g).map((p, i) => p.startsWith('@') ? <span key={i} className="text-lime">{p}</span> : p);
