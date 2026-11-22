'use client';

import { Button, Card, PageTitle, Skeleton, useUi } from '@/components/ui';
import { fetchApi, formatBytes } from '@/lib/api';
import { useEffect, useState } from 'react';

type Stats = { totalSize: number; avatarsSize: number; messagesSize: number; storiesSize: number; filesCount: number; byType: Record<'image' | 'video' | 'audio' | 'other', number> };

export default function StorageView() {
    const { toast, confirm } = useUi();
    const [s, setS] = useState<Stats | null>(null);
    const [days, setDays] = useState(365);
    const [busy, setBusy] = useState(false);

    const load = () => fetchApi<Stats>('/admin/storage/stats').then(setS).catch(e => toast(e.message, true));
    useEffect(() => { load(); }, []); // eslint-disable-line react-hooks/exhaustive-deps

    const cleanup = async () => {
        if (!(await confirm({ title: `Delete files older than ${days} days?`, body: 'Old photos, voice notes and avatars are removed from disk for good. Messages that pointed to them show as unavailable.', confirm: 'Delete files', danger: true }))) return;
        setBusy(true);
        try {
            const r = await fetchApi('/admin/storage/cleanup', { method: 'POST', body: JSON.stringify({ days }) });
            toast(`${r.deletedCount} files deleted · ${formatBytes(r.freedSize)} freed`);
            load();
        } catch (e: any) { toast(e.message, true); } finally { setBusy(false); }
    };

    const parts = s ? [
        { label: 'Chat media', hint: 'Encrypted photos and voice notes', v: s.messagesSize, color: '#7b5cff' },
        { label: 'Avatars', hint: 'Profile photos', v: s.avatarsSize, color: '#2e7bff' },
        { label: 'Stories', hint: '24-hour posts', v: s.storiesSize, color: '#f05a9d' },
    ] : [];

    return (
        <>
            <PageTitle title="Storage" subtitle="Uploaded files on the server disk." action={<Button icon="refresh" onClick={load}>Refresh</Button>} />
            {!s ? <Skeleton className="h-64" /> : (
                <div className="grid gap-4 xl:grid-cols-3">
                    <Card className="xl:col-span-2">
                        <div className="text-sm text-muted">Total used</div>
                        <div className="num mt-1 text-6xl font-semibold tracking-tight">{formatBytes(s.totalSize)}</div>
                        <div className="mt-1 text-sm text-muted"><span className="num">{s.filesCount.toLocaleString()}</span> files</div>

                        <div className="mt-8 flex h-4 gap-1 overflow-hidden rounded-full">
                            {parts.filter(p => p.v).map(p => <div key={p.label} title={`${p.label}: ${formatBytes(p.v)}`} style={{ flex: p.v, background: p.color }} className="rounded-full" />)}
                            {!s.totalSize && <div className="flex-1 rounded-full bg-white/[0.06]" />}
                        </div>
                        <div className="mt-6 grid gap-3 sm:grid-cols-3">
                            {parts.map(p => (
                                <div key={p.label} className="rounded-2xl bg-white/[0.04] p-4">
                                    <div className="flex items-center gap-2 text-sm"><i className="h-2.5 w-2.5 rounded-full" style={{ background: p.color }} />{p.label}</div>
                                    <div className="num mt-2 text-2xl font-semibold">{formatBytes(p.v)}</div>
                                    <div className="mt-0.5 text-xs text-muted">{p.hint}</div>
                                </div>
                            ))}
                        </div>
                    </Card>

                    <Card title="Clean up old files">
                        <p className="text-sm text-muted">Free space by deleting uploads older than a cutoff. This can’t be undone.</p>
                        <label className="mt-5 block text-sm text-muted" htmlFor="days">Older than</label>
                        <div className="mt-2 flex items-center gap-3">
                            <input id="days" type="range" min={30} max={730} step={15} value={days} onChange={e => setDays(+e.target.value)} className="flex-1 accent-[#ddfb5c]" />
                            <span className="num w-20 text-right">{days} days</span>
                        </div>
                        <div className="mt-2 flex flex-wrap gap-2">
                            {[90, 180, 365].map(d => <button key={d} onClick={() => setDays(d)} className={`rounded-full px-3 py-1 text-xs ${days === d ? 'bg-white/15' : 'bg-white/[0.05] text-muted hover:text-text'}`}>{d}d</button>)}
                        </div>
                        <Button kind="danger" icon="trash" className="mt-6 w-full" disabled={busy} onClick={cleanup}>{busy ? 'Deleting…' : 'Delete old files'}</Button>
                    </Card>
                </div>
            )}
        </>
    );
}
