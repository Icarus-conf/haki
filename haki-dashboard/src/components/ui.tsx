'use client';

import { API_URL } from '@/lib/api';
import { createContext, useCallback, useContext, useRef, useState } from 'react';

/* ---------- Icons (inline, 24px stroke) ---------- */
const paths: Record<string, string> = {
    grid: 'M4 4h7v7H4zM13 4h7v4h-7zM13 10h7v10h-7zM4 13h7v7H4z',
    users: 'M16 19v-1a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v1M9 10a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7M22 19v-1a4 4 0 0 0-3-3.9M16 3.1a3.5 3.5 0 0 1 0 6.8',
    chat: 'M21 12a8 8 0 0 1-11.6 7.1L4 20l1-4.6A8 8 0 1 1 21 12z',
    megaphone: 'M3 11v2a1 1 0 0 0 1 1h2l5 4V6L6 10H4a1 1 0 0 0-1 1zM15 8a5 5 0 0 1 0 8M18 5a9 9 0 0 1 0 14',
    database: 'M4 6c0-1.7 3.6-3 8-3s8 1.3 8 3-3.6 3-8 3-8-1.3-8-3zM4 6v6c0 1.7 3.6 3 8 3s8-1.3 8-3V6M4 12v6c0 1.7 3.6 3 8 3s8-1.3 8-3v-6',
    terminal: 'M4 17l6-5-6-5M12 19h8',
    logout: 'M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4M10 17l5-5-5-5M15 12H3',
    search: 'M11 18a7 7 0 1 0 0-14 7 7 0 0 0 0 14zM20 20l-3.5-3.5',
    trash: 'M4 7h16M10 11v6M14 11v6M5 7l1 12a2 2 0 0 0 2 2h8a2 2 0 0 0 2-2l1-12M9 7V4h6v3',
    ban: 'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM5.6 5.6l12.8 12.8',
    check: 'M5 12.5l4.5 4.5L19 7.5',
    refresh: 'M20 11a8 8 0 1 0-2.3 5.7M20 4v7h-7',
    shield: 'M12 3l8 3v6c0 4.5-3.4 8.3-8 9-4.6-.7-8-4.5-8-9V6z',
    lock: 'M6 11h12v10H6zM8 11V7a4 4 0 0 1 8 0v4',
    bolt: 'M13 2L4 14h7l-1 8 9-12h-7z',
    x: 'M6 6l12 12M18 6L6 18',
    menu: 'M4 7h16M4 12h16M4 17h16',
    pause: 'M8 5v14M16 5v14',
    play: 'M7 4l13 8-13 8z',
    flag: 'M5 21V4M5 4h11l-2 4 2 4H5',
    radar: 'M12 12l6-6M12 21a9 9 0 1 1 9-9M12 17a5 5 0 1 1 5-5',
    key: 'M15 7a4 4 0 1 1-3.9 4.9L4 19v2h3l1-1v-2h2l1.5-1.5M16 8h.01',
    history: 'M3 12a9 9 0 1 0 3-6.7L3 8M3 3v5h5M12 7v5l3 2',
    copy: 'M9 9h11v11H9zM5 15H4V4h11v1',
    plus: 'M12 5v14M5 12h14',
    laptop: 'M5 5h14v10H5zM2 19h20',
    phone: 'M8 2h8a1 1 0 0 1 1 1v18a1 1 0 0 1-1 1H8a1 1 0 0 1-1-1V3a1 1 0 0 1 1-1zM11 18h2',
    globe: 'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM3 12h18M12 3c2.5 2.5 3.5 5.5 3.5 9s-1 6.5-3.5 9c-2.5-2.5-3.5-5.5-3.5-9s1-6.5 3.5-9',
    link: 'M10 14a4 4 0 0 0 5.7 0l3-3a4 4 0 0 0-5.7-5.7l-1 1M14 10a4 4 0 0 0-5.7 0l-3 3a4 4 0 0 0 5.7 5.7l1-1',
};

export function Icon({ name, size = 18, className = '' }: { name: keyof typeof paths | string; size?: number; className?: string }) {
    return (
        <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={1.8}
            strokeLinecap="round" strokeLinejoin="round" className={className} aria-hidden>
            <path d={paths[name]} />
        </svg>
    );
}

/* ---------- Surfaces ---------- */
export function Card({ title, action, className = '', children, delay = 0 }: {
    title?: React.ReactNode; action?: React.ReactNode; className?: string; children: React.ReactNode; delay?: number;
}) {
    return (
        <section className={`glass rise rounded-3xl p-5 ${className}`} style={{ animationDelay: `${delay}ms` }}>
            {(title || action) && (
                <header className="mb-4 flex items-center justify-between gap-3">
                    {title && <h3 className="text-sm font-medium text-muted">{title}</h3>}
                    {action}
                </header>
            )}
            {children}
        </section>
    );
}

export function PageTitle({ title, subtitle, action }: { title: string; subtitle?: string; action?: React.ReactNode }) {
    return (
        <div className="mb-6 flex flex-wrap items-end justify-between gap-4">
            <div>
                <h1 className="font-display text-4xl font-semibold tracking-tight md:text-5xl">{title}</h1>
                {subtitle && <p className="mt-1.5 text-muted">{subtitle}</p>}
            </div>
            {action}
        </div>
    );
}

type ButtonKind = 'lime' | 'ghost' | 'danger';
export function Button({ kind = 'ghost', icon, children, className = '', ...rest }:
    React.ButtonHTMLAttributes<HTMLButtonElement> & { kind?: ButtonKind; icon?: string }) {
    const styles: Record<ButtonKind, string> = {
        lime: 'bg-lime text-on-lime hover:brightness-110 font-semibold',
        ghost: 'bg-white/[0.06] text-text hover:bg-white/[0.1] border border-line',
        danger: 'bg-danger/15 text-danger hover:bg-danger/25 border border-danger/25',
    };
    return (
        <button {...rest}
            className={`inline-flex items-center justify-center gap-2 rounded-full px-4 py-2 text-sm transition disabled:cursor-not-allowed disabled:opacity-40 ${styles[kind]} ${className}`}>
            {icon && <Icon name={icon} size={16} />}
            {children}
        </button>
    );
}

export function Badge({ tone = 'muted', children }: { tone?: 'lime' | 'danger' | 'violet' | 'teal' | 'muted'; children: React.ReactNode }) {
    const tones = {
        lime: 'bg-lime/15 text-lime',
        danger: 'bg-danger/15 text-danger',
        violet: 'bg-violet/20 text-[#b9a8ff]',
        teal: 'bg-teal/15 text-teal',
        muted: 'bg-white/[0.07] text-muted',
    };
    return <span className={`inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-xs font-medium ${tones[tone]}`}>{children}</span>;
}

const auras = [['#d6c8ff', '#7b5cff'], ['#bfe0ff', '#2e7bff'], ['#ffd0e6', '#f05a9d'], ['#ffe2b8', '#ff8a3d'], ['#c9fff0', '#18b39b']];

/** Same idea as the app's AuraAvatar: photo if uploaded, else initials on a gradient from the id. */
export function Avatar({ id, name, url, size = 36, online }: { id: number; name: string; url?: string | null; size?: number; online?: boolean }) {
    const [a, b] = auras[id % auras.length];
    const initials = name.replace(/[_\d]+/g, ' ').trim().split(/\s+/).map(w => w[0]).slice(0, 2).join('').toUpperCase() || '?';
    return (
        <span className="relative inline-block shrink-0" style={{ width: size, height: size }}>
            {url?.startsWith('/uploads/') ? (
                // eslint-disable-next-line @next/next/no-img-element
                <img src={`${API_URL}${url}`} alt="" className="h-full w-full rounded-[35%] object-cover" />
            ) : (
                <span className="flex h-full w-full items-center justify-center rounded-[35%] font-semibold text-[#0b0b12]"
                    style={{ background: `linear-gradient(135deg, ${a}, ${b})`, fontSize: size * 0.36 }}>{initials}</span>
            )}
            {online && <span className="pulse-dot absolute -right-0.5 -bottom-0.5 h-3 w-3 rounded-full border-2 border-ink bg-lime" />}
        </span>
    );
}

export function Segmented<T extends string>({ value, options, onChange }: { value: T; options: { value: T; label: string; count?: number }[]; onChange: (v: T) => void }) {
    return (
        <div className="inline-flex rounded-full border border-line bg-white/[0.04] p-1" role="tablist">
            {options.map(o => (
                <button key={o.value} role="tab" aria-selected={value === o.value} onClick={() => onChange(o.value)}
                    className={`rounded-full px-3.5 py-1.5 text-sm transition ${value === o.value ? 'bg-white/[0.12] text-text' : 'text-muted hover:text-text'}`}>
                    {o.label}{o.count !== undefined && <span className="num ml-1.5 text-xs opacity-60">{o.count}</span>}
                </button>
            ))}
        </div>
    );
}

export function Empty({ children }: { children: React.ReactNode }) {
    return <div className="py-12 text-center text-sm text-muted">{children}</div>;
}

export function Skeleton({ className = '' }: { className?: string }) {
    return <div className={`animate-pulse rounded-3xl bg-white/[0.05] ${className}`} />;
}

/* ---------- Toasts + confirm dialog (replace alert/confirm) ---------- */
type Toast = { id: number; text: string; error?: boolean };
type ConfirmOpts = { title: string; body?: string; confirm?: string; danger?: boolean };
const Ctx = createContext<{ toast: (text: string, error?: boolean) => void; confirm: (o: ConfirmOpts) => Promise<boolean> } | null>(null);
export const useUi = () => useContext(Ctx)!;

export function UiProvider({ children }: { children: React.ReactNode }) {
    const [toasts, setToasts] = useState<Toast[]>([]);
    const [ask, setAsk] = useState<ConfirmOpts | null>(null);
    const resolver = useRef<(v: boolean) => void>(null);

    const toast = useCallback((text: string, error = false) => {
        const id = Date.now() + Math.random();
        setToasts(t => [...t, { id, text, error }]);
        setTimeout(() => setToasts(t => t.filter(x => x.id !== id)), 3800);
    }, []);

    const confirm = useCallback((o: ConfirmOpts) => {
        setAsk(o);
        return new Promise<boolean>(r => { resolver.current = r; });
    }, []);
    const answer = (v: boolean) => { resolver.current?.(v); setAsk(null); };

    return (
        <Ctx.Provider value={{ toast, confirm }}>
            {children}
            <div className="pointer-events-none fixed right-4 bottom-4 z-50 flex flex-col items-end gap-2" aria-live="polite">
                {toasts.map(t => (
                    <div key={t.id} className={`glass rise pointer-events-auto flex items-center gap-2 rounded-2xl px-4 py-3 text-sm ${t.error ? 'text-danger' : ''}`}>
                        <Icon name={t.error ? 'x' : 'check'} size={16} className={t.error ? '' : 'text-lime'} />{t.text}
                    </div>
                ))}
            </div>
            {ask && (
                <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4 backdrop-blur-sm" onClick={() => answer(false)}>
                    <div role="dialog" aria-modal className="glass rise w-full max-w-sm rounded-3xl bg-surface/80 p-6" onClick={e => e.stopPropagation()}
                        onKeyDown={e => e.key === 'Escape' && answer(false)}>
                        <h2 className="font-display text-2xl font-semibold">{ask.title}</h2>
                        {ask.body && <p className="mt-2 text-sm text-muted">{ask.body}</p>}
                        <div className="mt-6 flex justify-end gap-2">
                            <Button onClick={() => answer(false)}>Cancel</Button>
                            <Button autoFocus kind={ask.danger ? 'danger' : 'lime'} onClick={() => answer(true)}>{ask.confirm ?? 'Confirm'}</Button>
                        </div>
                    </div>
                </div>
            )}
        </Ctx.Provider>
    );
}
