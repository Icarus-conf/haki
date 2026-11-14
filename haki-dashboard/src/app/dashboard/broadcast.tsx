'use client';

import { Button, Card, PageTitle, useUi } from '@/components/ui';
import { fetchApi } from '@/lib/api';
import { useEffect, useState } from 'react';

const MAX = 280;
type Sent = { text: string; at: string };

export default function BroadcastView() {
    const { toast, confirm } = useUi();
    const [msg, setMsg] = useState('');
    const [online, setOnline] = useState<number | null>(null);
    // Only rendered after a click, never prerendered, so reading storage here is safe
    const [sent, setSent] = useState<Sent[]>(() => { try { return JSON.parse(localStorage.getItem('broadcasts') ?? '[]'); } catch { return []; } });

    useEffect(() => {
        fetchApi('/admin/overview').then(d => setOnline(d.totals.online)).catch(() => { });
    }, []);

    const send = async (e: React.FormEvent) => {
        e.preventDefault();
        const text = msg.trim();
        if (!text) return;
        if (!(await confirm({ title: 'Send to everyone online?', body: `${online ?? 'Everyone'} people connected right now will see it as a banner.`, confirm: 'Send' }))) return;
        try {
            await fetchApi('/admin/broadcast', { method: 'POST', body: JSON.stringify({ message: text }) });
            const next = [{ text, at: new Date().toISOString() }, ...sent].slice(0, 10);
            setSent(next);
            try { localStorage.setItem('broadcasts', JSON.stringify(next)); } catch { }
            setMsg('');
            toast('Broadcast sent');
        } catch (e: any) { toast(e.message, true); }
    };

    return (
        <>
            <PageTitle title="Broadcast" subtitle="A system banner for everyone connected right now. Not stored, not encrypted, so keep it public." />
            <div className="grid gap-4 xl:grid-cols-2">
                <Card>
                    <form onSubmit={send}>
                        <label htmlFor="bc" className="text-sm text-muted">Announcement</label>
                        <textarea id="bc" value={msg} onChange={e => setMsg(e.target.value.slice(0, MAX))} rows={5} placeholder="Maintenance tonight at 2am, chats stay safe."
                            className="mt-2 w-full resize-none rounded-2xl border border-line bg-white/[0.04] p-4 text-[15px] outline-none focus:border-lime/50" />
                        <div className="mt-3 flex items-center justify-between">
                            <span className={`num text-xs ${msg.length > MAX - 20 ? 'text-amber' : 'text-muted'}`}>{msg.length}/{MAX}</span>
                            <Button kind="lime" icon="megaphone" disabled={!msg.trim()}>Send to {online ?? '…'} online</Button>
                        </div>
                    </form>
                </Card>

                <Card title="Preview on the phone">
                    <div className="mx-auto max-w-sm rounded-[2rem] border border-line bg-ink p-4">
                        <div className="glass flex gap-3 rounded-2xl p-3.5">
                            <span className="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl bg-lime font-display font-bold text-on-lime">h</span>
                            <div className="min-w-0">
                                <div className="text-xs text-muted">Haki · now</div>
                                <div className="mt-0.5 text-sm break-words">{msg.trim() || 'Your announcement shows here.'}</div>
                            </div>
                        </div>
                    </div>
                </Card>

                {sent.length > 0 && (
                    <Card title="Sent from this browser" className="xl:col-span-2">
                        <ul className="divide-y divide-line">
                            {sent.map((s, i) => (
                                <li key={i} className="flex items-start justify-between gap-4 py-3 text-sm">
                                    <span className="break-words">{s.text}</span>
                                    <span className="shrink-0 text-muted">{new Date(s.at).toLocaleString([], { dateStyle: 'short', timeStyle: 'short' })}</span>
                                </li>
                            ))}
                        </ul>
                    </Card>
                )}
            </div>
        </>
    );
}
