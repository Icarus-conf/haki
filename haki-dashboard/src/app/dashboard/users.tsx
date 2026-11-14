'use client';

import { Avatar, Badge, Button, Card, Empty, Icon, PageTitle, Segmented, Skeleton, useUi } from '@/components/ui';
import { fetchApi, timeAgo } from '@/lib/api';
import { useEffect, useMemo, useState } from 'react';

type User = {
    id: number; username: string; email: string; displayName: string | null; avatarUrl: string | null; role: string;
    isBanned: boolean; createdAt: string; hasKey: boolean; messages: number; lastMessageAt: string | null;
    friends: number; groups: number; online: boolean;
};
type Filter = 'all' | 'online' | 'admins' | 'banned';
type Sort = 'newest' | 'active' | 'recent';

export default function UsersView() {
    const { toast, confirm } = useUi();
    const [users, setUsers] = useState<User[] | null>(null);
    const [q, setQ] = useState('');
    const [filter, setFilter] = useState<Filter>('all');
    const [sort, setSort] = useState<Sort>('newest');

    const load = () => fetchApi<User[]>('/admin/users').then(setUsers).catch(e => toast(e.message, true));
    useEffect(() => { load(); }, []); // eslint-disable-line react-hooks/exhaustive-deps

    const shown = useMemo(() => {
        if (!users) return [];
        const needle = q.trim().toLowerCase();
        return users
            .filter(u => filter === 'all' || (filter === 'online' && u.online) || (filter === 'admins' && u.role === 'admin') || (filter === 'banned' && u.isBanned))
            .filter(u => !needle || [u.username, u.email, u.displayName ?? ''].some(s => s.toLowerCase().includes(needle)))
            .sort((a, b) => sort === 'active' ? b.messages - a.messages
                : sort === 'recent' ? (b.lastMessageAt ?? '').localeCompare(a.lastMessageAt ?? '')
                    : b.createdAt.localeCompare(a.createdAt));
    }, [users, q, filter, sort]);

    const toggleBan = async (u: User) => {
        const ban = !u.isBanned;
        const ok = await confirm(ban
            ? { title: `Ban ${u.username}?`, body: 'They are signed out everywhere right away and can’t sign back in until unbanned.', confirm: 'Ban', danger: true }
            : { title: `Unban ${u.username}?`, body: 'They can sign in again.', confirm: 'Unban' });
        if (!ok) return;
        try {
            await fetchApi(`/admin/users/${u.id}/${ban ? 'ban' : 'unban'}`, { method: 'PATCH' });
            setUsers(list => list!.map(x => x.id === u.id ? { ...x, isBanned: ban, online: ban ? false : x.online } : x));
            toast(ban ? `${u.username} banned` : `${u.username} can sign in again`);
        } catch (e: any) { toast(e.message, true); }
    };

    const count = (f: Filter) => users?.filter(u => f === 'online' ? u.online : f === 'admins' ? u.role === 'admin' : f === 'banned' ? u.isBanned : true).length;

    return (
        <>
            <PageTitle title="People" subtitle={users ? `${users.length} accounts · ${count('online')} online right now` : 'Loading…'}
                action={<Button icon="refresh" onClick={load}>Refresh</Button>} />

            <div className="mb-4 flex flex-wrap items-center gap-3">
                <label className="relative min-w-[220px] flex-1">
                    <Icon name="search" className="absolute top-1/2 left-4 -translate-y-1/2 text-muted" />
                    <input value={q} onChange={e => setQ(e.target.value)} placeholder="Search name, username or email" aria-label="Search people"
                        className="w-full rounded-full border border-line bg-white/[0.04] py-2.5 pr-4 pl-11 text-sm outline-none focus:border-lime/50" />
                </label>
                <Segmented value={filter} onChange={setFilter} options={[
                    { value: 'all', label: 'All', count: count('all') }, { value: 'online', label: 'Online', count: count('online') },
                    { value: 'admins', label: 'Admins', count: count('admins') }, { value: 'banned', label: 'Banned', count: count('banned') }]} />
                <select value={sort} onChange={e => setSort(e.target.value as Sort)} aria-label="Sort"
                    className="rounded-full border border-line bg-surface px-4 py-2.5 text-sm outline-none">
                    <option value="newest">Newest first</option>
                    <option value="active">Most messages</option>
                    <option value="recent">Recently active</option>
                </select>
            </div>

            <Card className="!p-0 overflow-hidden">
                {!users ? <div className="space-y-2 p-5">{[...Array(6)].map((_, i) => <Skeleton key={i} className="h-12 !rounded-2xl" />)}</div>
                    : shown.length === 0 ? <Empty>No one matches.</Empty> : (
                        <div className="overflow-x-auto">
                            <table className="w-full text-sm">
                                <thead>
                                    <tr className="border-b border-line text-left text-xs text-muted">
                                        <th className="px-5 py-3 font-medium">Person</th>
                                        <th className="hidden px-3 py-3 font-medium md:table-cell">Joined</th>
                                        <th className="px-3 py-3 text-right font-medium">Messages</th>
                                        <th className="hidden px-3 py-3 font-medium lg:table-cell">Last sent</th>
                                        <th className="hidden px-3 py-3 font-medium xl:table-cell">Circle</th>
                                        <th className="px-3 py-3 font-medium">Status</th>
                                        <th className="px-5 py-3"><span className="sr-only">Actions</span></th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {shown.map(u => (
                                        <tr key={u.id} className="border-b border-line/60 transition last:border-0 hover:bg-white/[0.03]">
                                            <td className="px-5 py-3">
                                                <div className="flex items-center gap-3">
                                                    <Avatar id={u.id} name={u.displayName || u.username} url={u.avatarUrl} online={u.online} />
                                                    <div className="min-w-0">
                                                        <div className="flex items-center gap-2 font-medium">
                                                            <span className="truncate">{u.displayName || u.username}</span>
                                                            {u.role === 'admin' && <Badge tone="violet">admin</Badge>}
                                                        </div>
                                                        <div className="truncate text-xs text-muted">@{u.username} · {u.email}</div>
                                                    </div>
                                                </div>
                                            </td>
                                            <td className="hidden px-3 py-3 whitespace-nowrap text-muted md:table-cell">{new Date(u.createdAt).toLocaleDateString()}</td>
                                            <td className="num px-3 py-3 text-right">{u.messages.toLocaleString()}</td>
                                            <td className="hidden px-3 py-3 whitespace-nowrap text-muted lg:table-cell">{timeAgo(u.lastMessageAt)}</td>
                                            <td className="hidden px-3 py-3 whitespace-nowrap text-muted xl:table-cell">
                                                <span className="num">{u.friends}</span> friends · <span className="num">{u.groups}</span> groups
                                            </td>
                                            <td className="px-3 py-3 whitespace-nowrap">
                                                <div className="flex flex-wrap gap-1.5">
                                                    {u.isBanned ? <Badge tone="danger">Banned</Badge> : u.online ? <Badge tone="lime">Online</Badge> : <Badge>Offline</Badge>}
                                                    {!u.hasKey && <Badge tone="muted">no key</Badge>}
                                                </div>
                                            </td>
                                            <td className="px-5 py-3 text-right">
                                                {u.role !== 'admin' && (
                                                    <Button kind={u.isBanned ? 'ghost' : 'danger'} icon={u.isBanned ? 'check' : 'ban'} onClick={() => toggleBan(u)} className="!py-1.5">
                                                        {u.isBanned ? 'Unban' : 'Ban'}
                                                    </Button>
                                                )}
                                            </td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                    )}
            </Card>
        </>
    );
}
