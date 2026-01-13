'use client';

import { fetchApi } from '@/lib/api';
import { useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';
import { Bar, BarChart, CartesianGrid, Legend, Line, LineChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from 'recharts';

interface User {
    id: number;
    username: string;
    email: string;
    role: string;
    isBanned: boolean;
    createdAt: string;
}

export default function DashboardPage() {
    const [activeTab, setActiveTab] = useState('dashboard');

    // Data States
    const [stats, setStats] = useState<{ usersCount: number; messagesCount: number } | null>(null);
    const [users, setUsers] = useState<User[]>([]);
    const [storageStats, setStorageStats] = useState<any>(null);
    const [logs, setLogs] = useState<any[]>([]);
    const [analytics, setAnalytics] = useState<any[]>([]);

    // UI States
    const [broadcastMsg, setBroadcastMsg] = useState('');
    const [loading, setLoading] = useState(true);
    const router = useRouter();

    const loadData = async () => {
        try {
            const statsRes = await fetchApi('/admin/stats');
            setStats(statsRes);

            const usersRes = await fetchApi('/admin/users');
            setUsers(usersRes);

            try {
                const storageRes = await fetchApi('/admin/storage/stats');
                setStorageStats(storageRes);
            } catch (e) { console.error('Storage stats error', e); }

            try {
                const analyticsRes = await fetchApi('/admin/analytics');
                setAnalytics(prepareChartData(analyticsRes.newUsers, analyticsRes.messages));
            } catch (e) { console.error('Analytics error', e); }

        } catch (e: any) {
            console.error(e);
            if (e.message && (e.message.includes('403') || e.message.includes('Forbidden'))) {
                alert('Access Denied');
                router.push('/');
            }
        } finally {
            setLoading(false);
        }
    };

    const prepareChartData = (usersData: any[], msgsData: any[]) => {
        const map = new Map();
        const add = (arr: any[], key: string) => {
            if (!arr) return;
            arr.forEach((item: any) => {
                const d = item.date;
                if (!map.has(d)) map.set(d, { date: d });
                map.get(d)[key] = parseInt(item.count);
            });
        }
        add(usersData, 'users');
        add(msgsData, 'messages');

        return Array.from(map.values()).sort((a, b) => a.date.localeCompare(b.date));
    };


    const fetchLogs = async () => {
        try {
            const res = await fetchApi('/admin/logs?lines=100');
            setLogs(res);
        } catch (e) {
            console.error(e);
        }
    };

    useEffect(() => {
        loadData();
    }, []);

    useEffect(() => {
        if (activeTab === 'logs') {
            fetchLogs();
            const interval = setInterval(fetchLogs, 5000);
            return () => clearInterval(interval);
        }
    }, [activeTab]);

    const toggleBan = async (user: User) => {
        const action = user.isBanned ? 'unban' : 'ban';
        if (!window.confirm(`Are you sure you want to ${action} ${user.username}?`)) return;
        try {
            await fetchApi(`/admin/users/${user.id}/${action}`, { method: 'PATCH' });
            setUsers(users.map(u => u.id === user.id ? { ...u, isBanned: !u.isBanned } : u));
        } catch (e: any) { alert(e.message); }
    };

    const handleBroadcast = async (e: React.FormEvent) => {
        e.preventDefault();
        if (!broadcastMsg.trim()) return;
        if (!confirm('Send System Message to ALL active users?')) return;
        try {
            await fetchApi('/admin/broadcast', {
                method: 'POST',
                body: JSON.stringify({ message: broadcastMsg })
            });
            alert('Broadcast Sent!');
            setBroadcastMsg('');
        } catch (e: any) { alert(e.message); }
    };

    const handleCleanup = async () => {
        const days = window.prompt('Delete files older than (days):', '365');
        if (!days) return;
        try {
            const res = await fetchApi('/admin/storage/cleanup', {
                method: 'POST',
                body: JSON.stringify({ days: parseInt(days) })
            });
            alert(`Cleanup complete: ${res.deletedCount} files deleted (${formatBytes(res.freedSize)} freed)`);
            const s = await fetchApi('/admin/storage/stats');
            setStorageStats(s);
        } catch (e: any) { alert(e.message); }
    };

    const formatBytes = (bytes: number) => {
        if (bytes === 0) return '0 B';
        const k = 1024;
        const sizes = ['B', 'KB', 'MB', 'GB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
    };

    const handleLogout = () => {
        localStorage.removeItem('token');
        router.push('/');
    };

    if (loading) {
        return <div className="min-h-screen flex items-center justify-center bg-gray-100 dark:bg-gray-900 text-gray-500">Loading...</div>;
    }

    return (
        <div className="min-h-screen bg-gray-100 dark:bg-gray-900">
            {/* Top Bar */}
            <div className="bg-white dark:bg-gray-800 shadow">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                    <div className="flex justify-between h-16 items-center">
                        <h1 className="text-xl font-bold text-gray-800 dark:text-white">Admin Dashboard</h1>
                        <button onClick={handleLogout} className="text-sm text-red-600 hover:text-red-800 font-medium">Logout</button>
                    </div>
                </div>
            </div>

            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
                {/* Tabs */}
                <div className="flex space-x-4 mb-8 overflow-x-auto pb-2 border-b border-gray-200 dark:border-gray-700">
                    {['dashboard', 'users', 'storage', 'logs'].map((tab) => (
                        <button
                            key={tab}
                            onClick={() => setActiveTab(tab)}
                            className={`px-4 py-2 text-sm font-medium rounded-md whitespace-nowrap ${activeTab === tab
                                    ? 'bg-blue-600 text-white'
                                    : 'bg-white dark:bg-gray-800 text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700'
                                }`}
                        >
                            {tab.charAt(0).toUpperCase() + tab.slice(1)}
                        </button>
                    ))}
                </div>

                {/* Content */}
                <div className="space-y-6">

                    {/* DASHBOARD TAB */}
                    {activeTab === 'dashboard' && (
                        <>
                            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                                <div className="bg-white dark:bg-gray-800 p-6 rounded-lg shadow">
                                    <h3 className="text-gray-500 dark:text-gray-400 text-sm font-medium">Total Users</h3>
                                    <p className="text-3xl font-bold text-gray-900 dark:text-white mt-2">{stats?.usersCount}</p>
                                </div>
                                <div className="bg-white dark:bg-gray-800 p-6 rounded-lg shadow">
                                    <h3 className="text-gray-500 dark:text-gray-400 text-sm font-medium">Total Messages</h3>
                                    <p className="text-3xl font-bold text-gray-900 dark:text-white mt-2">{stats?.messagesCount}</p>
                                </div>
                                <div className="bg-white dark:bg-gray-800 p-6 rounded-lg shadow">
                                    <h3 className="text-gray-500 dark:text-gray-400 text-sm font-medium">Storage</h3>
                                    <p className="text-3xl font-bold text-gray-900 dark:text-white mt-2">{storageStats ? formatBytes(storageStats.totalSize) : '...'}</p>
                                </div>
                            </div>

                            {/* Charts Section */}
                            <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                                <div className="bg-white dark:bg-gray-800 p-6 rounded-lg shadow">
                                    <h3 className="text-lg font-medium dark:text-white mb-4">Message Activity (Last 7 Days)</h3>
                                    <div className="h-64">
                                        <ResponsiveContainer width="100%" height="100%">
                                            <LineChart data={analytics}>
                                                <CartesianGrid strokeDasharray="3 3" />
                                                <XAxis dataKey="date" stroke="#888888" fontSize={12} tickLine={false} axisLine={false} />
                                                <YAxis stroke="#888888" fontSize={12} tickLine={false} axisLine={false} tickFormatter={(value) => `${value}`} />
                                                <Tooltip />
                                                <Legend />
                                                <Line type="monotone" dataKey="messages" stroke="#8884d8" name="Messages" strokeWidth={2} />
                                            </LineChart>
                                        </ResponsiveContainer>
                                    </div>
                                </div>

                                <div className="bg-white dark:bg-gray-800 p-6 rounded-lg shadow">
                                    <h3 className="text-lg font-medium dark:text-white mb-4">User Growth (Last 7 Days)</h3>
                                    <div className="h-64">
                                        <ResponsiveContainer width="100%" height="100%">
                                            <BarChart data={analytics}>
                                                <CartesianGrid strokeDasharray="3 3" />
                                                <XAxis dataKey="date" stroke="#888888" fontSize={12} tickLine={false} axisLine={false} />
                                                <YAxis stroke="#888888" fontSize={12} tickLine={false} axisLine={false} allowDecimals={false} />
                                                <Tooltip />
                                                <Legend />
                                                <Bar dataKey="users" fill="#82ca9d" name="New Users" radius={[4, 4, 0, 0]} />
                                            </BarChart>
                                        </ResponsiveContainer>
                                    </div>
                                </div>
                            </div>

                            <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
                                <h2 className="text-lg font-medium text-gray-900 dark:text-white mb-4">Broadcast System Message</h2>
                                <form onSubmit={handleBroadcast} className="flex gap-4">
                                    <input
                                        type="text"
                                        value={broadcastMsg}
                                        onChange={(e) => setBroadcastMsg(e.target.value)}
                                        placeholder="Enter announcement..."
                                        className="flex-1 rounded-md border-gray-300 p-2 bg-gray-50 dark:bg-gray-700 border dark:text-white"
                                        required
                                    />
                                    <button type="submit" className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700 font-medium">Send</button>
                                </form>
                            </div>
                        </>
                    )}

                    {/* USERS TAB */}
                    {activeTab === 'users' && (
                        <div className="bg-white dark:bg-gray-800 rounded-lg shadow overflow-hidden">
                            <div className="px-6 py-4 border-b border-gray-200 dark:border-gray-700">
                                <h2 className="text-lg font-medium text-gray-900 dark:text-white">Registered Users</h2>
                            </div>
                            <div className="overflow-x-auto">
                                <table className="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
                                    <thead className="bg-gray-50 dark:bg-gray-900">
                                        <tr>
                                            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">ID</th>
                                            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Username</th>
                                            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Email</th>
                                            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Role</th>
                                            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
                                            <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Actions</th>
                                        </tr>
                                    </thead>
                                    <tbody className="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
                                        {users.map((user) => (
                                            <tr key={user.id}>
                                                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{user.id}</td>
                                                <td className="px-6 py-4 whitespace-nowrap text-sm font-medium dark:text-white">{user.username}</td>
                                                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{user.email}</td>
                                                <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">{user.role}</td>
                                                <td className="px-6 py-4 whitespace-nowrap">
                                                    <span className={`px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${user.isBanned ? 'bg-red-100 text-red-800' : 'bg-green-100 text-green-800'}`}>
                                                        {user.isBanned ? 'Banned' : 'Active'}
                                                    </span>
                                                </td>
                                                <td className="px-6 py-4 whitespace-nowrap text-sm">
                                                    <button
                                                        onClick={() => toggleBan(user)}
                                                        className={`text-sm font-medium ${user.isBanned ? 'text-green-600 hover:text-green-900' : 'text-red-600 hover:text-red-900'}`}
                                                    >
                                                        {user.isBanned ? 'Unban' : 'Ban'}
                                                    </button>
                                                </td>
                                            </tr>
                                        ))}
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    )}

                    {/* STORAGE TAB */}
                    {activeTab === 'storage' && storageStats && (
                        <div className="space-y-6">
                            <div className="bg-white dark:bg-gray-800 p-6 rounded-lg shadow">
                                <h3 className="text-lg font-medium dark:text-white mb-4">Storage Usage by Type</h3>
                                <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                                    <div className="p-4 bg-gray-50 dark:bg-gray-700 rounded border border-gray-100 dark:border-gray-600">
                                        <span className="text-gray-500 dark:text-gray-400 text-xs uppercase">Images</span>
                                        <p className="font-bold text-xl dark:text-white">{formatBytes(storageStats.byType.image)}</p>
                                    </div>
                                    <div className="p-4 bg-gray-50 dark:bg-gray-700 rounded border border-gray-100 dark:border-gray-600">
                                        <span className="text-gray-500 dark:text-gray-400 text-xs uppercase">Videos</span>
                                        <p className="font-bold text-xl dark:text-white">{formatBytes(storageStats.byType.video)}</p>
                                    </div>
                                    <div className="p-4 bg-gray-50 dark:bg-gray-700 rounded border border-gray-100 dark:border-gray-600">
                                        <span className="text-gray-500 dark:text-gray-400 text-xs uppercase">Audio</span>
                                        <p className="font-bold text-xl dark:text-white">{formatBytes(storageStats.byType.audio)}</p>
                                    </div>
                                    <div className="p-4 bg-gray-50 dark:bg-gray-700 rounded border border-gray-100 dark:border-gray-600">
                                        <span className="text-gray-500 dark:text-gray-400 text-xs uppercase">Other</span>
                                        <p className="font-bold text-xl dark:text-white">{formatBytes(storageStats.byType.other)}</p>
                                    </div>
                                </div>
                            </div>

                            <div className="bg-white dark:bg-gray-800 p-6 rounded-lg shadow">
                                <h3 className="text-lg font-medium dark:text-white mb-4">Cleanup</h3>
                                <p className="text-sm text-gray-500 dark:text-gray-400 mb-4">Delete old files to free up disk space.</p>
                                <button
                                    onClick={handleCleanup}
                                    className="px-6 py-2 bg-orange-600 text-white rounded hover:bg-orange-700 font-medium"
                                >
                                    Cleanup Tool
                                </button>
                            </div>
                        </div>
                    )}

                    {/* LOGS TAB */}
                    {activeTab === 'logs' && (
                        <div className="bg-gray-900 rounded-lg shadow overflow-hidden flex flex-col h-[600px]">
                            <div className="bg-gray-800 px-4 py-2 flex justify-between items-center text-sm">
                                <span className="text-gray-300 font-mono">logs/server.log</span>
                                <button onClick={fetchLogs} className="text-blue-400 hover:text-blue-300">Refresh</button>
                            </div>
                            <div className="flex-1 overflow-auto p-4 font-mono text-sm bg-black text-gray-300">
                                {logs.length === 0 && <span className="text-gray-500">No logs or loading...</span>}
                                {logs.map((log, i) => (
                                    <div key={i} className="mb-1 hover:bg-gray-900 p-0.5 rounded">
                                        <span className="text-gray-500 select-none mr-2">
                                            {log.timestamp ? new Date(log.timestamp).toLocaleTimeString() : ''}
                                        </span>
                                        <span className={`font-bold mr-2 ${log.level === 'error' ? 'text-red-500' :
                                                log.level === 'warn' ? 'text-yellow-500' :
                                                    'text-blue-500'
                                            }`}>
                                            {log.level?.toUpperCase()}
                                        </span>
                                        <span className="text-gray-300">{log.message}</span>
                                        {log.context && <span className="text-gray-600 ml-2 text-xs">[{log.context}]</span>}
                                        {log.stack && <pre className="text-red-900 text-xs mt-1 overflow-x-auto">{log.stack}</pre>}
                                    </div>
                                ))}
                            </div>
                        </div>
                    )}

                </div>
            </div>
        </div>
    );
}
