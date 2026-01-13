const API_URL = 'http://localhost:3000';

export async function fetchApi(path: string, options: RequestInit = {}) {
    let token = '';
    if (typeof window !== 'undefined') {
        token = localStorage.getItem('token') || '';
    }

    const headers: Record<string, string> = {
        'Content-Type': 'application/json',
    };

    if (token) {
        headers['Authorization'] = `Bearer ${token}`;
    }

    // Merge extra headers
    if (options.headers) {
        Object.assign(headers, options.headers);
    }

    const res = await fetch(`${API_URL}${path}`, { ...options, headers });

    if (res.status === 401) {
        if (typeof window !== 'undefined') {
            localStorage.removeItem('token');
            window.location.href = '/'; // Redirect to login
        }
    }

    if (!res.ok) {
        const text = await res.text();
        try {
            const json = JSON.parse(text);
            throw new Error(json.message || res.statusText);
        } catch (e) {
            throw new Error(text || res.statusText);
        }
    }

    return res.json();
}
