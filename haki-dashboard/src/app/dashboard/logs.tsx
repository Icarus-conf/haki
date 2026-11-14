'use client';

import { Button, Card, Icon, PageTitle, Segmented, useUi } from '@/components/ui';
import { fetchApi } from '@/lib/api';
import { useEffect, useState } from 'react';

type Log = { timestamp?: string; level?: string; message: string; context?: string; stack?: string };
type Level = 'all' | 'error' | 'warn' | 'info';

export default function LogsView() {
    const { toast } = useUi();
    const [logs, setLogs] = useState<Log[]>([]);
    const [live, setLive] = useState(true);
    const [level, setLevel] = useState<Level>('all');
    const [q, setQ] = useState('');

    const load = () => fetchApi<Log[]>('/admin/logs?lines=300').then(setLogs).catch(e => toast(e.message, true));
    useEffect(() => {
        load();
        if (!live) return;
        const t = setInterval(load, 4000);
        return () => clearInterval(t);
    }, [live]); // eslint-disable-line react-hooks/exhaustive-deps

    const needle = q.trim().toLowerCase();
    const shown = logs.filter(l => (level === 'all' || (l.level ?? 'info') === level) && (!needle || `${l.message} ${l.context ?? ''}`.toLowerCase().includes(needle)));
    const n = (lv: Level) => logs.filter(l => (l.level ?? 'info') === lv).length;
    const color = (lv?: string) => lv === 'error' ? 'text-danger' : lv === 'warn' ? 'text-amber' : 'text-[#9fb4ff]';

    return (
        <>
            <PageTitle title="Logs" subtitle="Last 300 lines of the server log, newest first."
                action={<Button icon={live ? 'pause' : 'play'} onClick={() => setLive(l => !l)}>{live ? 'Pause' : 'Resume'}</Button>} />
            <div className="mb-4 flex flex-wrap items-center gap-3">
                <Segmented value={level} onChange={setLevel} options={[
                    { value: 'all', label: 'All', count: logs.length }, { value: 'error', label: 'Errors', count: n('error') },
                    { value: 'warn', label: 'Warnings', count: n('warn') }, { value: 'info', label: 'Info', count: n('info') }]} />
                <label className="relative min-w-[200px] flex-1">
                    <Icon name="search" className="absolute top-1/2 left-4 -translate-y-1/2 text-muted" />
                    <input value={q} onChange={e => setQ(e.target.value)} placeholder="Search logs" aria-label="Search logs"
                        className="w-full rounded-full border border-line bg-white/[0.04] py-2.5 pr-4 pl-11 text-sm outline-none focus:border-lime/50" />
                </label>
            </div>
            <Card className="!p-0 overflow-hidden">
                <div className="flex items-center gap-2 border-b border-line px-5 py-3 text-xs text-muted">
                    {live && <span className="pulse-dot h-2 w-2 rounded-full bg-lime" />}
                    <span className="num">logs/server.log</span><span className="ml-auto">{shown.length} lines</span>
                </div>
                <div className="num h-[65vh] overflow-auto bg-black/40 p-4 text-[12.5px] leading-6">
                    {shown.length === 0 && <span className="text-muted">Nothing to show.</span>}
                    {shown.map((l, i) => (
                        <div key={i} className="rounded px-1.5 hover:bg-white/[0.04]">
                            <span className="mr-3 text-muted/70 select-none">{l.timestamp ? new Date(l.timestamp).toLocaleTimeString() : '--:--:--'}</span>
                            <span className={`mr-3 inline-block w-11 font-semibold uppercase ${color(l.level)}`}>{(l.level ?? 'info').slice(0, 5)}</span>
                            {l.context && <span className="mr-2 text-violet">[{l.context}]</span>}
                            <span className="break-all text-text/90">{l.message}</span>
                            {l.stack && <pre className="mt-1 mb-2 overflow-x-auto pl-[7.5rem] text-[11px] text-danger/70">{l.stack}</pre>}
                        </div>
                    ))}
                </div>
            </Card>
        </>
    );
}
