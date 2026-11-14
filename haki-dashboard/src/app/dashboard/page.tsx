'use client';

import { Icon, UiProvider } from '@/components/ui';
import { fetchApi } from '@/lib/api';
import { useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';
import Access from './access';
import Audit from './audit';
import Broadcast from './broadcast';
import Devices from './devices';
import Logs from './logs';
import Lounge from './lounge';
import Overview from './overview';
import Reports from './reports';
import Safety from './safety';
import Storage from './storage';
import Users from './users';

const tabs = [
    { id: 'overview', label: 'Overview', icon: 'grid', View: Overview },
    { id: 'users', label: 'People', icon: 'users', View: Users },
    { id: 'devices', label: 'Devices', icon: 'laptop', View: Devices },
    { id: 'reports', label: 'Reports', icon: 'flag', View: Reports },
    { id: 'safety', label: 'Spam signals', icon: 'radar', View: Safety },
    { id: 'lounge', label: 'Lounge', icon: 'chat', View: Lounge },
    { id: 'broadcast', label: 'Broadcast', icon: 'megaphone', View: Broadcast },
    { id: 'access', label: 'Sign-ups', icon: 'key', View: Access },
    { id: 'storage', label: 'Storage', icon: 'database', View: Storage },
    { id: 'audit', label: 'Audit log', icon: 'history', View: Audit },
    { id: 'logs', label: 'Logs', icon: 'terminal', View: Logs },
] as const;
type TabId = (typeof tabs)[number]['id'];

export default function DashboardPage() {
    const router = useRouter();
    const [tab, setTab] = useState<TabId>('overview');
    const [me, setMe] = useState<{ username: string; id: number } | null>(null);
    const [menuOpen, setMenuOpen] = useState(false);
    const [openReports, setOpenReports] = useState(0);

    useEffect(() => {
        if (!localStorage.getItem('token')) return router.replace('/');
        // The hash is client-only (reading it during render would break hydration); follow it for links and back/forward
        const sync = () => {
            const fromHash = window.location.hash.slice(1) as TabId;
            setTab(tabs.some(t => t.id === fromHash) ? fromHash : 'overview');
        };
        sync();
        window.addEventListener('hashchange', sync);
        fetchApi('/users/me').then(setMe).catch(() => { });
        const count = () => fetchApi('/admin/overview').then(d => setOpenReports(d.totals.openReports)).catch(() => { });
        count();
        const t = setInterval(count, 30000);
        return () => { window.removeEventListener('hashchange', sync); clearInterval(t); };
    }, [router]);

    const go = (id: TabId) => {
        setMenuOpen(false);
        setTab(id);
        history.pushState(null, '', `#${id}`); // back/forward fire hashchange → sync
    };

    const logout = () => {
        localStorage.removeItem('token');
        router.push('/');
    };

    const View = tabs.find(t => t.id === tab)!.View;

    return (
        <UiProvider>
            <div className="min-h-screen lg:grid lg:grid-cols-[248px_1fr]">
                {/* Mobile bar */}
                <div className="sticky top-0 z-30 flex items-center justify-between border-b border-line bg-ink/70 px-4 py-3 backdrop-blur-xl lg:hidden">
                    <Brand />
                    <button aria-label="Menu" onClick={() => setMenuOpen(o => !o)} className="rounded-full p-2 hover:bg-white/10">
                        <Icon name={menuOpen ? 'x' : 'menu'} size={22} />
                    </button>
                </div>

                {/* Sidebar */}
                <aside className={`${menuOpen ? 'block' : 'hidden'} fixed inset-x-0 top-[61px] bottom-0 z-20 bg-ink/95 p-4 backdrop-blur-xl lg:sticky lg:top-0 lg:block lg:h-screen lg:bg-transparent lg:p-5`}>
                    <div className="flex h-full flex-col">
                        <div className="mb-8 hidden px-2 pt-1 lg:block"><Brand /></div>
                        <nav className="flex flex-col gap-1">
                            {tabs.map(t => (
                                <button key={t.id} onClick={() => go(t.id)} aria-current={tab === t.id ? 'page' : undefined}
                                    className={`group flex items-center gap-3 rounded-2xl px-3.5 py-2.5 text-[15px] transition ${tab === t.id
                                        ? 'bg-white/[0.08] text-text shadow-[inset_0_1px_0_rgb(255_255_255/0.06)]'
                                        : 'text-muted hover:bg-white/[0.04] hover:text-text'}`}>
                                    <Icon name={t.icon} className={tab === t.id ? 'text-lime' : ''} />
                                    {t.label}
                                    {t.id === 'reports' && openReports > 0 && (
                                        <span className="num ml-auto rounded-full bg-danger px-2 py-0.5 text-xs font-semibold text-ink">{openReports}</span>
                                    )}
                                </button>
                            ))}
                        </nav>
                        <div className="mt-auto">
                            <div className="glass mb-3 rounded-2xl p-3.5 text-xs leading-relaxed text-muted">
                                <div className="mb-1 flex items-center gap-1.5 font-medium text-text"><Icon name="lock" size={14} className="text-lime" />Encrypted by design</div>
                                Private and group chats are unreadable here. You see counts and the public Lounge.
                            </div>
                            <div className="flex items-center justify-between rounded-2xl px-2 py-2">
                                <div className="min-w-0">
                                    <div className="truncate text-sm font-medium">{me?.username ?? '…'}</div>
                                    <div className="text-xs text-muted">Administrator</div>
                                </div>
                                <button onClick={logout} aria-label="Sign out" title="Sign out" className="rounded-full p-2 text-muted hover:bg-white/10 hover:text-text">
                                    <Icon name="logout" />
                                </button>
                            </div>
                        </div>
                    </div>
                </aside>

                <main className="mx-auto w-full max-w-[1400px] px-4 py-6 sm:px-6 lg:px-10 lg:py-10">
                    <View key={tab} />
                </main>
            </div>
        </UiProvider>
    );
}

function Brand() {
    return (
        <div className="flex items-center gap-2.5">
            <span className="flex h-8 w-8 items-center justify-center rounded-xl bg-lime font-display text-base font-bold text-on-lime">h</span>
            <span className="font-display text-lg font-semibold">Haki Control</span>
        </div>
    );
}
