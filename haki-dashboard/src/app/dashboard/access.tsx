'use client';

import { Badge, Button, Card, Empty, Icon, PageTitle, Segmented, Skeleton, useUi } from '@/components/ui';
import { fetchApi, timeAgo } from '@/lib/api';
import { useEffect, useState } from 'react';

type Mode = 'open' | 'invite' | 'closed';
type Invite = { id: number; code: string; maxUses: number; uses: number; note: string | null; createdBy: string; expiresAt: string | null; revoked: boolean; createdAt: string };

const modeText: Record<Mode, string> = {
    open: 'Anyone with the app can create an account.',
    invite: 'New accounts need an invite code. People already in keep using Haki as normal.',
    closed: 'Nobody can create an account. Existing accounts are not affected.',
};

const stateOf = (i: Invite) =>
    i.revoked ? { label: 'revoked', tone: 'muted' as const }
        : i.expiresAt && new Date(i.expiresAt) < new Date() ? { label: 'expired', tone: 'muted' as const }
            : i.uses >= i.maxUses ? { label: 'used up', tone: 'violet' as const }
                : { label: 'active', tone: 'lime' as const };

export default function AccessView() {
    const { toast, confirm } = useUi();
    const [mode, setMode] = useState<Mode | null>(null);
    const [invites, setInvites] = useState<Invite[] | null>(null);
    const [uses, setUses] = useState(1);
    const [days, setDays] = useState(7);
    const [note, setNote] = useState('');

    useEffect(() => {
        fetchApi<{ mode: Mode; invites: Invite[] }>('/admin/access')
            .then(d => { setMode(d.mode); setInvites(d.invites); })
            .catch(e => toast(e.message, true));
    }, [toast]);

    const changeMode = async (m: Mode) => {
        if (m === 'closed' && !(await confirm({ title: 'Close sign-ups?', body: 'Nobody new can join until you open them again.', confirm: 'Close sign-ups', danger: true }))) return;
        try {
            await fetchApi('/admin/access/mode', { method: 'PUT', body: JSON.stringify({ mode: m }) });
            setMode(m);
            toast(m === 'open' ? 'Sign-ups are open' : m === 'invite' ? 'Invite only' : 'Sign-ups closed');
        } catch (e: any) { toast(e.message, true); }
    };

    const create = async (e: React.FormEvent) => {
        e.preventDefault();
        try {
            const row = await fetchApi<Invite>('/admin/invites', { method: 'POST', body: JSON.stringify({ maxUses: uses, days, note }) });
            setInvites(l => [row, ...(l ?? [])]);
            setNote('');
            await navigator.clipboard?.writeText(row.code).catch(() => { });
            toast(`Code ${row.code} copied`);
        } catch (e: any) { toast(e.message, true); }
    };

    const revoke = async (i: Invite) => {
        if (!(await confirm({ title: `Revoke ${i.code}?`, body: 'It stops working right away. Accounts already made with it stay.', confirm: 'Revoke', danger: true }))) return;
        try {
            await fetchApi(`/admin/invites/${i.id}`, { method: 'DELETE' });
            setInvites(l => l!.map(x => x.id === i.id ? { ...x, revoked: true } : x));
            toast('Invite revoked');
        } catch (e: any) { toast(e.message, true); }
    };

    const copy = (code: string) => navigator.clipboard?.writeText(code).then(() => toast(`Code ${code} copied`)).catch(() => { });
    const field = 'mt-1.5 w-full rounded-2xl border border-line bg-white/[0.04] px-3.5 py-2.5 text-sm outline-none focus:border-lime/50';

    return (
        <>
            <PageTitle title="Sign-ups" subtitle="Control who can create an account." />
            <div className="grid gap-4 xl:grid-cols-[1fr_360px]">
                <div className="space-y-4">
                    <Card title="Who can join">
                        {!mode ? <Skeleton className="h-12" /> : (
                            <>
                                <Segmented value={mode} onChange={changeMode} options={[
                                    { value: 'open', label: 'Anyone' }, { value: 'invite', label: 'Invite only' }, { value: 'closed', label: 'Closed' }]} />
                                <p className="mt-3 text-sm text-muted">{modeText[mode]}</p>
                            </>
                        )}
                    </Card>

                    <Card title="Invite codes" className="overflow-hidden">
                        {!invites ? <Skeleton className="h-24" />
                            : invites.length === 0 ? <Empty>No invite codes yet.</Empty> : (
                                <div className="-mx-5 -mb-5 overflow-x-auto border-t border-line">
                                    <table className="w-full text-sm">
                                        <thead className="text-left text-xs text-muted">
                                            <tr className="border-b border-line">
                                                <th className="px-5 py-3 font-medium">Code</th><th className="px-3 py-3 font-medium">Used</th>
                                                <th className="px-3 py-3 font-medium">Expires</th><th className="px-3 py-3 font-medium">Note</th>
                                                <th className="px-3 py-3 font-medium">State</th><th />
                                            </tr>
                                        </thead>
                                        <tbody>
                                            {invites.map(i => {
                                                const st = stateOf(i);
                                                return (
                                                    <tr key={i.id} className="border-b border-line/60 last:border-0">
                                                        <td className="px-5 py-3">
                                                            <button onClick={() => copy(i.code)} title="Copy" className="num inline-flex items-center gap-2 font-medium tracking-wider hover:text-lime">
                                                                {i.code}<Icon name="copy" size={14} className="text-muted" />
                                                            </button>
                                                            <div className="text-xs text-muted">by {i.createdBy} · {timeAgo(i.createdAt)}</div>
                                                        </td>
                                                        <td className="num px-3 py-3">{i.uses} / {i.maxUses}</td>
                                                        <td className="px-3 py-3 text-muted">{i.expiresAt ? new Date(i.expiresAt).toLocaleDateString() : 'never'}</td>
                                                        <td className="max-w-[180px] truncate px-3 py-3 text-muted">{i.note ?? '—'}</td>
                                                        <td className="px-3 py-3"><Badge tone={st.tone}>{st.label}</Badge></td>
                                                        <td className="px-3 py-3 text-right">
                                                            {st.label === 'active' && <button onClick={() => revoke(i)} aria-label={`Revoke ${i.code}`} title="Revoke" className="rounded-full p-2 text-muted hover:bg-danger/15 hover:text-danger"><Icon name="trash" size={16} /></button>}
                                                        </td>
                                                    </tr>
                                                );
                                            })}
                                        </tbody>
                                    </table>
                                </div>
                            )}
                    </Card>
                </div>

                <Card title="New invite code">
                    <form onSubmit={create} className="space-y-3">
                        <label className="block text-sm text-muted">How many people can use it
                            <input type="number" min={1} max={1000} value={uses} onChange={e => setUses(Number(e.target.value))} className={field} />
                        </label>
                        <label className="block text-sm text-muted">Expires after
                            <select value={days} onChange={e => setDays(Number(e.target.value))} className={field}>
                                <option value={1}>1 day</option><option value={7}>7 days</option><option value={30}>30 days</option><option value={0}>Never</option>
                            </select>
                        </label>
                        <label className="block text-sm text-muted">Note (optional)
                            <input value={note} maxLength={80} onChange={e => setNote(e.target.value)} placeholder="Who it’s for" className={field} />
                        </label>
                        <Button kind="lime" icon="plus" type="submit" className="w-full">Create and copy</Button>
                        {mode !== 'invite' && <p className="text-xs text-muted">Codes only matter while sign-ups are set to Invite only.</p>}
                    </form>
                </Card>
            </div>
        </>
    );
}
