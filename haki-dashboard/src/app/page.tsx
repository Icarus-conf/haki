'use client';

import { Icon } from '@/components/ui';
import { API_URL } from '@/lib/api';
import { useRouter } from 'next/navigation';
import { useState } from 'react';

export default function LoginPage() {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [code, setCode] = useState('');
  const [needCode, setNeedCode] = useState(false);
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  const router = useRouter();

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setBusy(true);
    try {
      // Accounts with two-step login answer 401 + twoFactor until the code is sent too
      const raw = await fetch(`${API_URL}/auth/login`, {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username, password, code: needCode ? code : undefined, deviceName: 'Haki Control', platform: 'web' }),
      });
      const res = await raw.json().catch(() => ({}));
      if (!raw.ok) {
        if (res.twoFactor) setNeedCode(true);
        throw new Error(res.twoFactor && !needCode ? '' : raw.status === 401 && !res.twoFactor ? 'Wrong username or password' : res.message);
      }
      localStorage.setItem('token', res.access_token);
      router.push('/dashboard');
    } catch (err: any) {
      setError(err.message || 'Login failed');
      setBusy(false);
    }
  };

  const field = 'mt-1.5 block w-full rounded-2xl border border-line bg-white/[0.04] px-4 py-3 text-text placeholder:text-muted/60 outline-none transition focus:border-lime/60 focus:bg-white/[0.06]';

  return (
    <main className="grid min-h-screen lg:grid-cols-[1.1fr_1fr]">
      {/* Brand side */}
      <div className="relative hidden flex-col justify-between overflow-hidden p-12 lg:flex">
        <div className="flex items-center gap-2.5">
          <span className="flex h-9 w-9 items-center justify-center rounded-xl bg-lime font-display text-lg font-bold text-on-lime">h</span>
          <span className="font-display text-xl font-semibold">Haki Control</span>
        </div>
        <div>
          <h1 className="font-display text-6xl leading-[1.02] font-semibold tracking-tight xl:text-7xl">
            Run the place.<br /><span className="text-muted">Never read the mail.</span>
          </h1>
          <p className="mt-6 max-w-md text-lg text-muted">
            Chats are end-to-end encrypted. This console sees counts, timestamps and the public Lounge. Nothing else.
          </p>
        </div>
        <div className="flex gap-6 text-sm text-muted">
          <span className="flex items-center gap-2"><Icon name="lock" size={16} className="text-lime" />E2EE by default</span>
          <span className="flex items-center gap-2"><Icon name="shield" size={16} className="text-lime" />Admin role only</span>
        </div>
      </div>

      {/* Form side */}
      <div className="flex items-center justify-center p-4 sm:p-8">
        <form onSubmit={handleLogin} className="glass rise w-full max-w-md rounded-[2rem] p-8 sm:p-10">
          <span className="mb-8 flex h-11 w-11 items-center justify-center rounded-2xl bg-lime font-display text-xl font-bold text-on-lime lg:hidden">h</span>
          <h2 className="font-display text-3xl font-semibold">Sign in</h2>
          <p className="mt-1 text-sm text-muted">Use an account with the admin role.</p>

          {error && (
            <div role="alert" className="mt-6 rounded-2xl border border-danger/30 bg-danger/10 px-4 py-3 text-sm text-danger">{error}</div>
          )}

          <label className="mt-6 block text-sm text-muted">
            Username
            <input autoFocus autoComplete="username" value={username} onChange={e => setUsername(e.target.value)} className={field} required />
          </label>
          <label className="mt-4 block text-sm text-muted">
            Password
            <input type="password" autoComplete="current-password" value={password} onChange={e => setPassword(e.target.value)} className={field} required />
          </label>
          {needCode && (
            <label className="mt-4 block text-sm text-muted">
              Code from your authenticator app
              <input autoFocus inputMode="numeric" autoComplete="one-time-code" pattern="\d{6}" maxLength={6} value={code}
                onChange={e => setCode(e.target.value.replace(/\D/g, ''))} className={`${field} num tracking-[0.4em]`} required />
            </label>
          )}
          <button type="submit" disabled={busy}
            className="mt-8 w-full rounded-full bg-lime py-3.5 font-semibold text-on-lime transition hover:brightness-110 disabled:opacity-60">
            {busy ? 'Signing in…' : 'Sign in'}
          </button>
        </form>
      </div>
    </main>
  );
}
