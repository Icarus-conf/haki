'use client';

import { Avatar, Badge, Button, Card, Empty, Icon, PageTitle, Segmented, Skeleton, useUi } from '@/components/ui';
import { fetchApi, timeAgo } from '@/lib/api';
import { useEffect, useState } from 'react';

type Report = {
    id: number; messageId: number; reason: string; note: string | null; content: string | null; attachmentType: string | null;
    chat: 'direct' | 'group' | 'lounge'; status: string; createdAt: string; resolvedAt: string | null;
    reporterId: number; reporterUsername: string; reporterName: string | null;
    reportedId: number; reportedUsername: string; reportedName: string | null; reportedAvatar: string | null; reportedBanned: boolean;
    reportsAgainst: number; messageExists: boolean;
};
type Status = 'open' | 'resolved' | 'dismissed';

const reasons: Record<string, string> = {
    spam: 'Spam', harassment: 'Harassment', hate: 'Hate speech', violence: 'Violence or threats',
    sexual: 'Sexual content', scam: 'Scam or fraud', other: 'Other',
};
const chats = { direct: 'Private chat', group: 'Group chat', lounge: 'Lounge' };

export default function ReportsView() {
    const { toast, confirm } = useUi();
    const [status, setStatus] = useState<Status>('open');
    const [list, setList] = useState<Report[] | null>(null);

    useEffect(() => {
        fetchApi<Report[]>(`/admin/reports?status=${status}`).then(setList).catch(e => toast(e.message, true));
    }, [status, toast]);

    const drop = (id: number) => setList(l => l!.filter(r => r.id !== id));

    const resolve = async (r: Report, next: Status) => {
        try {
            await fetchApi(`/admin/reports/${r.id}`, { method: 'PATCH', body: JSON.stringify({ status: next }) });
            drop(r.id);
            toast(next === 'dismissed' ? 'Report dismissed' : next === 'open' ? 'Report reopened' : 'Marked as handled');
        } catch (e: any) { toast(e.message, true); }
    };

    const removeMessage = async (r: Report) => {
        if (!(await confirm({ title: 'Delete this message?', body: `It disappears for everyone in the ${chats[r.chat].toLowerCase()} and the report is closed.`, confirm: 'Delete', danger: true }))) return;
        try {
            await fetchApi(`/admin/reports/${r.id}/message`, { method: 'DELETE' });
            drop(r.id);
            toast('Message deleted, report closed');
        } catch (e: any) { toast(e.message, true); }
    };

    const ban = async (r: Report) => {
        const who = r.reportedName || r.reportedUsername;
        if (!(await confirm({ title: `Ban ${who}?`, body: 'They are signed out everywhere right away. The report is closed.', confirm: 'Ban', danger: true }))) return;
        try {
            await fetchApi(`/admin/users/${r.reportedId}/ban`, { method: 'PATCH' });
            await fetchApi(`/admin/reports/${r.id}`, { method: 'PATCH', body: JSON.stringify({ status: 'resolved' }) });
            drop(r.id);
            toast(`${who} banned`);
        } catch (e: any) { toast(e.message, true); }
    };

    return (
        <>
            <PageTitle title="Reports" subtitle="Messages people flagged. For encrypted chats you only see what the reporter chose to send."
                action={<Segmented value={status} onChange={v => { setList(null); setStatus(v); }} options={[
                    { value: 'open', label: 'Open' }, { value: 'resolved', label: 'Handled' }, { value: 'dismissed', label: 'Dismissed' }]} />} />

            {!list ? <div className="space-y-3">{[...Array(3)].map((_, i) => <Skeleton key={i} className="h-44" />)}</div>
                : list.length === 0 ? <Card><Empty>{status === 'open' ? 'Nothing to review. 🎉' : 'Nothing here yet.'}</Empty></Card> : (
                    <div className="grid gap-4 xl:grid-cols-2">
                        {list.map((r, i) => (
                            <Card key={r.id} delay={i * 40}>
                                <div className="flex items-start gap-3">
                                    <Avatar id={r.reportedId} name={r.reportedName || r.reportedUsername} url={r.reportedAvatar} size={42} />
                                    <div className="min-w-0 flex-1">
                                        <div className="flex flex-wrap items-center gap-2">
                                            <span className="font-medium">{r.reportedName || r.reportedUsername}</span>
                                            <span className="text-sm text-muted">@{r.reportedUsername}</span>
                                            {r.reportedBanned && <Badge tone="danger">banned</Badge>}
                                            {r.reportsAgainst > 1 && <Badge tone="violet">{r.reportsAgainst} reports</Badge>}
                                        </div>
                                        <div className="mt-0.5 text-xs text-muted">
                                            {chats[r.chat]} · reported by @{r.reporterUsername} · {timeAgo(r.createdAt)}
                                        </div>
                                    </div>
                                    <Badge tone="danger">{reasons[r.reason] ?? r.reason}</Badge>
                                </div>

                                <blockquote className="mt-4 rounded-2xl border border-line bg-white/[0.04] p-4 text-[15px] leading-relaxed break-words whitespace-pre-wrap">
                                    {r.content ?? <span className="text-muted italic">{r.attachmentType ? `[${r.attachmentType}] — encrypted, not shared` : 'The reporter didn’t include the text.'}</span>}
                                </blockquote>
                                {r.chat !== 'lounge' && r.content && (
                                    <p className="mt-2 flex items-center gap-1.5 text-xs text-muted">
                                        <Icon name="lock" size={13} />As decrypted on the reporter’s phone. The server can’t verify it against the encrypted original.
                                    </p>
                                )}
                                {r.note && <p className="mt-3 text-sm"><span className="text-muted">Note: </span>{r.note}</p>}

                                <div className="mt-5 flex flex-wrap gap-2">
                                    {status === 'open' ? (
                                        <>
                                            {r.messageExists
                                                ? <Button kind="danger" icon="trash" onClick={() => removeMessage(r)}>Delete message</Button>
                                                : <Badge>message already gone</Badge>}
                                            {!r.reportedBanned && <Button kind="danger" icon="ban" onClick={() => ban(r)}>Ban</Button>}
                                            <Button icon="check" onClick={() => resolve(r, 'resolved')}>Handled</Button>
                                            <Button onClick={() => resolve(r, 'dismissed')}>Dismiss</Button>
                                        </>
                                    ) : (
                                        <>
                                            <span className="self-center text-sm text-muted">{status === 'resolved' ? 'Handled' : 'Dismissed'} {timeAgo(r.resolvedAt)}</span>
                                            <Button icon="refresh" onClick={() => resolve(r, 'open')}>Reopen</Button>
                                        </>
                                    )}
                                </div>
                            </Card>
                        ))}
                    </div>
                )}
        </>
    );
}
