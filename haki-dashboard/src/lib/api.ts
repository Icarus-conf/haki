export const API_URL = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:3000';

export async function fetchApi<T = any>(path: string, options: RequestInit = {}): Promise<T> {
    const token = typeof window !== 'undefined' ? localStorage.getItem('token') || '' : '';
    const headers: Record<string, string> = { 'Content-Type': 'application/json' };
    if (token) headers['Authorization'] = `Bearer ${token}`;
    if (options.headers) Object.assign(headers, options.headers);

    const res = await fetch(`${API_URL}${path}`, { ...options, headers });

    // A stale token on any admin call sends you back to sign in (not the login call itself)
    if (res.status === 401 && token && typeof window !== 'undefined') {
        localStorage.removeItem('token');
        window.location.href = '/';
    }

    if (!res.ok) {
        const text = await res.text();
        let message = text || res.statusText;
        try {
            const json = JSON.parse(text);
            message = Array.isArray(json.message) ? json.message.join(', ') : json.message || message;
        } catch { }
        throw new Error(message);
    }
    return res.json();
}

export function formatBytes(bytes: number) {
    if (!bytes) return '0 B';
    const k = 1024, sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
    const i = Math.min(Math.floor(Math.log(bytes) / Math.log(k)), sizes.length - 1);
    return `${parseFloat((bytes / k ** i).toFixed(1))} ${sizes[i]}`;
}

export function timeAgo(iso?: string | null) {
    if (!iso) return 'never';
    const s = Math.max(0, (Date.now() - new Date(iso).getTime()) / 1000);
    if (s < 60) return 'just now';
    if (s < 3600) return `${Math.floor(s / 60)}m ago`;
    if (s < 86400) return `${Math.floor(s / 3600)}h ago`;
    if (s < 86400 * 30) return `${Math.floor(s / 86400)}d ago`;
    return new Date(iso).toLocaleDateString();
}

export const compact = (n: number) => new Intl.NumberFormat('en', { notation: 'compact', maximumFractionDigits: 1 }).format(n);
