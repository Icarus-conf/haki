// Live two-user smoke test against the running Docker stack: `node scripts/smoke-test.js`
// Two-user end-to-end check of the Haki backend over real HTTP + Socket.IO.
const { io } = require('socket.io-client');
const { execSync } = require('child_process');
const API = 'http://localhost:3000';
const run = Date.now().toString(36);
let failures = 0;

const ok = (cond, label, extra = '') => {
  console.log(`${cond ? 'PASS' : 'FAIL'}  ${label}${extra ? '  — ' + extra : ''}`);
  if (!cond) failures++;
};
const http = async (method, path, token, body) => {
  const res = await fetch(API + path, {
    method,
    headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    body: body ? JSON.stringify(body) : undefined,
  });
  let data = null;
  try { data = await res.json(); } catch {}
  return { status: res.status, data };
};
const connect = (token) => new Promise((resolve, reject) => {
  const s = io(API, { transports: ['websocket'], auth: { token: `Bearer ${token}` }, forceNew: true });
  s.once('connect', () => resolve(s));
  s.once('connect_error', reject);
});
// Resolves with the next payload of `event` matching `pred`, or null after `ms`.
const next = (sock, event, pred = () => true, ms = 2500) => new Promise((resolve) => {
  const t = setTimeout(() => { sock.off(event, h); resolve(null); }, ms);
  const h = (d) => { if (pred(d)) { clearTimeout(t); sock.off(event, h); resolve(d); } };
  sock.on(event, h);
});
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function makeUser(name) {
  const username = `${name}_${run}`;
  const reg = await http('POST', '/auth/register', null, { username, email: `${username}@test.local`, password: 'password123' });
  const login = await http('POST', '/auth/login', null, { username, password: 'password123' });
  const me = await http('GET', '/users/me', login.data.access_token);
  await http('PATCH', '/users/profile', login.data.access_token, { publicKey: `PUBKEY-${username}` });
  return { username, token: login.data.access_token, id: me.data.id, me: me.data, reg };
}

const psql = (sql) => execSync(`docker exec haki_db psql -U user -d haki_db -tAc "${sql}"`).toString().trim();
// The test makes accounts, so sign-ups must be open while it runs; whatever was set is put back after
const signupBefore = psql(`select value from settings where key='signupMode'`) || 'open';
const restoreSignup = () => psql(`insert into settings (key, value) values ('signupMode', '${signupBefore}') on conflict (key) do update set value = '${signupBefore}'`);

(async () => {
  psql(`insert into settings (key, value) values ('signupMode', 'open') on conflict (key) do update set value = 'open'`);
  const A = await makeUser('alice'), B = await makeUser('bob'), C = await makeUser('carol');

  // --- Security fixes ---
  ok(A.reg.status === 201, 'register returns 201');
  ok(A.me && !('password' in A.me), '/users/me does not leak password hash');
  ok((await http('GET', '/users', A.token)).status === 404, 'GET /users (all emails) removed');
  ok((await http('GET', '/messages/link-preview?url=http://db:5432', A.token)).status === 404, 'server-side link fetcher removed (no SSRF / link leak)');

  // --- Friends via Haki code (username) ---
  const sa = await connect(A.token), sb = await connect(B.token);
  const reqEvt = next(sb, 'friend_request');
  const req = await http('POST', '/users/friends/requests', A.token, { username: B.username });
  ok(req.status === 201, 'friend request by username (Haki code)', `status ${req.status}`);
  ok(!!(await reqEvt), 'recipient gets live friend_request');
  const pending = await http('GET', '/users/friends/requests', B.token);
  const acceptedEvt = next(sa, 'friend_accepted');
  await http('POST', `/users/friends/requests/${pending.data[0].id}/accept`, B.token);
  ok(!!(await acceptedEvt), 'sender gets live friend_accepted');
  const bad = await http('POST', '/users/friends/requests', A.token, { username: 'nobody_' + run });
  ok(bad.status === 404 && /Haki code/.test(bad.data.message), 'unknown user → 404 with readable message', `${bad.status} ${bad.data?.message}`);

  // --- Presence ---
  const sa2 = await connect(A.token);
  await sleep(300);
  const onlineAfterClose = next(sb, 'online_users');
  sa2.disconnect();
  const ids = await onlineAfterClose;
  ok(ids && ids.includes(A.id) && ids.includes(B.id), 'user stays online when one of two devices disconnects', JSON.stringify(ids));

  // --- Messages, unread, read receipts ---
  const gotB = next(sb, 'message', (m) => m.tempId === 't1');
  const echoA = next(sa, 'message', (m) => m.tempId === 't1');
  sa.emit('message', { message: 'hello bob', recipientId: B.id, tempId: 't1' });
  const mB = await gotB, mA = await echoA;
  ok(mB && mB.message === 'hello bob', 'recipient receives message text unchanged', JSON.stringify(mB?.message));
  ok(mA && mA.tempId === 't1', 'sender gets echo with tempId (optimistic bubble replaced)');
  const skew = Math.abs(Date.parse(mB?.timestamp) - Date.now());
  ok(skew < 60_000, 'message timestamp is the real current time (no timezone shift)', `off by ${Math.round(skew / 60000)} min`);
  ok(mB && mB.isRead === false && mB.recipientId === B.id, 'new message is unread and carries recipientId', `isRead=${mB?.isRead}`);

  let friendsB = await http('GET', '/users/friends', B.token);
  let rowA = friendsB.data.find((f) => f.id === A.id);
  ok(rowA && rowA.unreadCount === 1, 'friend list unreadCount = 1', `got ${rowA?.unreadCount}`);
  ok(rowA && rowA.lastMessage?.content === 'hello bob', 'friend list lastMessage present');
  ok(rowA && !('password' in rowA), 'friend list does not leak password hash');

  const readEvt = next(sa, 'messages_read');
  sb.emit('mark_read', { friendId: A.id });
  const r = await readEvt;
  ok(r && r.readerId === B.id, 'sender notified messages_read', JSON.stringify(r));
  friendsB = await http('GET', '/users/friends', B.token);
  rowA = friendsB.data.find((f) => f.id === A.id);
  ok(rowA && rowA.unreadCount === 0, 'unreadCount back to 0 after mark_read', `got ${rowA?.unreadCount}`);

  // --- History: newest 50, oldest-first, read flag, recipient filter ---
  // In two bursts: the server allows 30 messages per 10 seconds per person
  for (let i = 0; i < 55; i++) {
    if (i === 20 || i === 40) await sleep(10500);
    sa.emit('message', { message: `bulk ${i}`, recipientId: B.id });
  }
  await sleep(2500);
  const histP = next(sa, 'history', (d) => d.recipientId === B.id);
  sa.emit('get_history', { recipientId: B.id });
  const hist = await histP;
  const msgs = hist?.messages || [];
  ok(msgs.length === 50, 'history returns 50 messages', `got ${msgs.length}`);
  ok(msgs.at(-1)?.message === 'bulk 54', 'history ends with the newest message', msgs.at(-1)?.message);
  ok(msgs.every((m, i) => i === 0 || m.timestamp >= msgs[i - 1].timestamp), 'history is oldest → newest');
  ok(msgs.every((m) => 'isRead' in m && 'recipientId' in m), 'history items carry isRead + recipientId');

  // --- Reactions ---
  const target = msgs.at(-1);
  const reactB = next(sb, 'message:reaction'), reactA = next(sa, 'message:reaction');
  sb.emit('message:react', { messageId: target.id, emoji: '❤️' });
  const [ra, rb] = await Promise.all([reactA, reactB]);
  ok(ra && rb && ra.reactions[0]?.userId === B.id && ra.reactions[0]?.username === B.username, 'reaction broadcast to both, flattened user', JSON.stringify(ra?.reactions));
  const sc = await connect(C.token);
  const leak = next(sa, 'message:reaction', () => true, 1500);
  sc.emit('message:react', { messageId: target.id, emoji: '😂' });
  ok((await leak) === null, 'outsider cannot react to a private message');
  const hist2P = next(sb, 'history', (d) => d.recipientId === A.id);
  sb.emit('get_history', { recipientId: A.id });
  const h2 = (await hist2P).messages.at(-1);
  ok(h2.reactions[0]?.userId === B.id, 'history reactions are flattened (not "Unknown")', JSON.stringify(h2.reactions));

  // --- Typing ---
  const typing = next(sb, 'user_typing');
  sa.emit('typing_start', { recipientId: B.id });
  const ty = await typing;
  ok(ty && ty.userId === A.id && ty.isTyping === true, 'typing indicator relayed');

  // --- Calls (signalling relay) ---
  const offer = next(sb, 'call_offer');
  sa.emit('call_user', { to: B.id, offer: { sdp: 'x', type: 'offer' } });
  const o = await offer;
  ok(o && o.from === A.id && o.offer.type === 'offer', 'call_offer reaches callee with caller id');
  const ans = next(sa, 'call_answer');
  sb.emit('call_answer', { to: A.id, answer: { sdp: 'y', type: 'answer' } });
  ok(!!(await ans), 'call_answer reaches caller');
  const ice = next(sb, 'ice_candidate');
  sa.emit('ice_candidate', { to: B.id, candidate: { candidate: 'c', sdpMid: '0', sdpMLineIndex: 0 } });
  ok(!!(await ice), 'ICE candidates relayed');
  const ended = next(sb, 'call_ended');
  sa.emit('call_end', { to: B.id });
  ok(!!(await ended), 'call_end reaches the other side');

  // --- Stories: post, live notify to friends, friends-only visibility ---
  const storyEvt = next(sb, 'story_posted');
  const form = new FormData();
  form.append('file', new Blob([Buffer.from('89504e470d0a1a0a', 'hex')], { type: 'image/png' }), 'story.png');
  const posted = await fetch(API + '/stories', { method: 'POST', headers: { Authorization: `Bearer ${A.token}` }, body: form });
  ok(posted.status === 201, 'story upload accepted', `status ${posted.status}`);
  ok((await storyEvt)?.userId === A.id, 'friend notified live of new story');
  const bStories = (await http('GET', '/stories/active', B.token)).data;
  ok(bStories.some((st) => st.userId === A.id), 'friend sees the story');
  const cStories = (await http('GET', '/stories/active', C.token)).data;
  ok(!cStories.some((st) => st.userId === A.id), 'non-friend does not see the story');

  // --- Edit, delete for me, pin ---
  const own = msgs.at(-2);
  const editedB = next(sb, 'message_edited', (m) => m.id === own.id);
  sa.emit('edit_message', { messageId: own.id, message: 'bulk 53 (edited)' });
  const ed = await editedB;
  ok(ed && ed.message === 'bulk 53 (edited)' && !!ed.editedAt, 'edit reaches the other side with editedAt');
  const notMine = next(sa, 'message_edited', (m) => m.message === 'hijack', 1500);
  sb.emit('edit_message', { messageId: own.id, message: 'hijack' });
  ok((await notMine) === null, 'only the sender can edit');
  const hidden = next(sb, 'message_hidden');
  sb.emit('hide_message', { messageId: own.id });
  ok((await hidden)?.messageId === own.id, 'delete-for-me confirmed to own devices');
  const hB = next(sb, 'history', (d) => d.recipientId === A.id);
  sb.emit('get_history', { recipientId: A.id });
  ok(!(await hB).messages.some((m) => m.id === own.id), 'hidden message gone from my history');
  const hA = next(sa, 'history', (d) => d.recipientId === B.id);
  sa.emit('get_history', { recipientId: B.id });
  ok((await hA).messages.some((m) => m.id === own.id), 'other person still has it');
  const pinEvt = next(sa, 'message_pinned');
  sb.emit('pin_message', { messageId: msgs[0].id, pinned: true });
  ok((await pinEvt)?.pinned === true, 'pin broadcast to both');
  const hp = next(sa, 'history', (d) => d.recipientId === B.id);
  sa.emit('get_history', { recipientId: B.id, limit: 200 });
  const hpd = await hp;
  ok(hpd.pinned.some((m) => m.id === msgs[0].id), 'history carries pinned messages');
  ok(hpd.messages.length > 50, 'search can ask for a longer history', `got ${hpd.messages.length}`);

  // --- Mentions (Lounge) ---
  const mention = next(sb, 'mention');
  sa.emit('message', { message: `hey @${B.username} look` });
  const mn = await mention;
  ok(mn && mn.text.includes('look'), 'mentioned user is notified');

  // --- Video call flag ---
  const vOffer = next(sb, 'call_offer');
  sa.emit('call_user', { to: B.id, offer: { sdp: 'x', type: 'offer' }, video: true });
  ok((await vOffer)?.video === true, 'video flag reaches the callee');

  // --- Groups ---
  const badGroup = await http('POST', '/groups', A.token, { name: 'X', memberIds: [C.id] });
  ok(badGroup.status === 400, 'cannot add a non-friend to a group');
  const groupEvt = next(sb, 'group_updated');
  const g = await http('POST', '/groups', A.token, { name: 'Weekend', memberIds: [B.id] });
  ok(g.status === 201 && g.data.members.length === 2 && g.data.members.every((m) => m.publicKey), 'group created with members and keys');
  ok((await groupEvt)?.groupId === g.data.id, 'members told about the new group');
  const gMsgB = next(sb, 'message', (m) => m.groupId === g.data.id);
  const leakC = next(sc, 'message', (m) => m.groupId === g.data.id, 1500);
  sa.emit('message', { message: 'CIPHERTEXT', groupId: g.data.id });
  ok((await gMsgB)?.message === 'CIPHERTEXT', 'group message reaches members');
  ok((await leakC) === null, 'outsider does not get group messages');
  sc.emit('message', { message: 'intruder', groupId: g.data.id });
  await sleep(500);
  const gh = next(sa, 'history', (d) => d.groupId === g.data.id);
  sa.emit('get_history', { groupId: g.data.id });
  const ghd = await gh;
  ok(ghd.messages.length === 1, 'outsider cannot post to a group', `got ${ghd.messages.length}`);
  const lh = next(sa, 'history', (d) => !d.recipientId && !d.groupId);
  sa.emit('get_history', {});
  ok(!(await lh).messages.some((m) => m.groupId), 'group messages never appear in the Lounge');
  const gTyping = next(sb, 'user_typing', (d) => d.groupId === g.data.id);
  sa.emit('typing_start', { groupId: g.data.id });
  ok(!!(await gTyping), 'group typing relayed with groupId');
  ok((await http('GET', '/groups', B.token)).data.some((x) => x.id === g.data.id && x.lastMessage), 'member lists the group with last message');
  ok((await http('GET', '/groups', C.token)).data.length === 0, 'outsider lists no groups');
  ok((await http('DELETE', `/groups/${g.data.id}/members/me`, B.token)).status === 200, 'member can leave');
  ok(!(await http('GET', '/groups', B.token)).data.some((x) => x.id === g.data.id), 'left group is gone from their list');

  // --- Polls (votes are option numbers; the question stays encrypted) ---
  const pollMsg = next(sb, 'message', (m) => m.tempId === 'poll1');
  sa.emit('message', { message: 'ENCRYPTED-POLL', recipientId: B.id, tempId: 'poll1' });
  const pm = await pollMsg;
  const votesA = next(sa, 'poll_votes', (d) => d.messageId === pm.id);
  sb.emit('poll_vote', { messageId: pm.id, options: [1] });
  ok((await votesA)?.pollVotes?.[B.id]?.[0] === 1, 'poll vote reaches both sides');
  const votes2 = next(sb, 'poll_votes', (d) => d.messageId === pm.id && d.pollVotes[A.id]);
  sa.emit('poll_vote', { messageId: pm.id, options: [0, 1, 99] });
  const v2 = await votes2;
  ok(v2 && v2.pollVotes[B.id][0] === 1 && v2.pollVotes[A.id].join() === '0,1', 'concurrent voters kept; bad options dropped', JSON.stringify(v2?.pollVotes));
  const leakPoll = next(sa, 'poll_votes', (d) => d.messageId === pm.id && d.pollVotes[C.id], 1200);
  sc.emit('poll_vote', { messageId: pm.id, options: [0] });
  ok((await leakPoll) === null, 'outsider cannot vote on a private poll');

  // --- Scheduled messages ---
  const sched = next(sa, 'message_scheduled', (m) => m.tempId === 'sch1');
  const early = next(sb, 'message', (m) => m.tempId === 'sch1', 3000);
  sa.emit('message', { message: 'LATER', recipientId: B.id, tempId: 'sch1', sendAt: new Date(Date.now() + 7000).toISOString() });
  const sm = await sched;
  ok(sm && sm.scheduledAt, 'sender gets the scheduled message back');
  ok((await early) === null, 'recipient does not get it early');
  const hs = next(sa, 'history', (d) => d.recipientId === B.id);
  sa.emit('get_history', { recipientId: B.id });
  const hsd = await hs;
  ok(hsd.scheduled.some((m) => m.id === sm.id) && !hsd.messages.some((m) => m.id === sm.id), 'scheduled list is separate in history');
  const hsB = next(sb, 'history', (d) => d.recipientId === A.id);
  sb.emit('get_history', { recipientId: A.id });
  ok(!(await hsB).scheduled.length, 'recipient sees nothing scheduled');
  const late = await next(sb, 'message', (m) => m.id === sm.id, 12000);
  ok(late && !late.scheduledAt && Math.abs(Date.parse(late.timestamp) - Date.now()) < 10000, 'delivered at its time');

  // --- Story views and loves ---
  const sf = new FormData();
  sf.append('file', new Blob([Buffer.from('89504e470d0a1a0a', 'hex')], { type: 'image/png' }), 's.png');
  const st = await (await fetch(API + '/stories', { method: 'POST', headers: { Authorization: `Bearer ${A.token}` }, body: sf })).json();
  ok((await http('POST', `/stories/${st.id}/view`, B.token)).status === 201, 'friend marks story seen');
  const loved = next(sa, 'story_liked');
  await http('POST', `/stories/${st.id}/like`, B.token, { liked: true });
  ok((await loved)?.userId === B.id, 'owner told about the love');
  const viewers = await http('GET', `/stories/${st.id}/viewers`, A.token);
  ok(viewers.data.length === 1 && viewers.data[0].liked && viewers.data[0].user.id === B.id, 'owner sees who viewed and loved');
  ok((await http('GET', `/stories/${st.id}/viewers`, B.token)).status === 403, 'others cannot see viewers');
  ok((await http('POST', `/stories/${st.id}/view`, C.token)).status === 404, 'non-friend cannot mark a story seen');
  const bList = (await http('GET', '/stories/active', B.token)).data.find((x) => x.id === st.id);
  const aList = (await http('GET', '/stories/active', A.token)).data.find((x) => x.id === st.id);
  ok(bList.seen && bList.liked && bList.viewCount === undefined, 'viewer sees own seen/loved, not counts');
  ok(aList.viewCount === 1 && aList.likeCount === 1, 'owner sees counts');

  // --- Push notifications (APNs not configured here: the server logs what it would send) ---
  const tokB = 'ab'.repeat(32);
  ok((await http('POST', '/push/devices', B.token, { token: tokB })).data?.ok === true, 'phone registers for push');
  ok((await http('POST', '/push/devices', B.token, { token: 'not-a-token' })).data?.ok === false, 'bad push token refused');
  sb.emit('app_state', { foreground: false });
  await sleep(300);
  sa.emit('message', { message: 'CIPHER', recipientId: B.id, tempId: 'push1' });
  await sleep(1200);
  const logs = () => execSync('docker logs haki_api --since 20s 2>&1').toString();
  ok(new RegExp(`would send message to users ${B.id}\\b`).test(logs()), 'backgrounded recipient gets a push');
  sb.emit('app_state', { foreground: true });
  await sleep(300);
  sa.emit('message', { message: 'CIPHER2', recipientId: B.id, tempId: 'push2' });
  await sleep(1200);
  ok((logs().match(new RegExp(`would send message to users ${B.id}\\b`, 'g')) || []).length === 1, 'no push while the app is open');
  const strangerCall = next(sc, 'call_rejected');
  const leakCall = next(sb, 'call_offer', () => true, 1500);
  sc.emit('call_user', { to: B.id, offer: { sdp: 'x', type: 'offer' } });
  ok(!!(await strangerCall) && (await leakCall) === null, 'non-friends cannot ring someone');
  await http('POST', '/push/devices/remove', B.token, { token: tokB });

  // --- Delete ---
  const del = next(sb, 'message_deleted');
  sa.emit('delete_message', { messageId: target.id });
  ok((await del)?.messageId === target.id, 'delete broadcast to recipient');

  // --- Disappearing messages ---
  const timerA = next(sa, 'disappearing_changed'), timerB = next(sb, 'disappearing_changed');
  sa.emit('set_disappearing', { recipientId: B.id, seconds: 3600 });
  const [tA, tB] = [await timerA, await timerB];
  ok(tA?.recipientId === B.id && tB?.recipientId === A.id && tB?.seconds === 3600, 'both people hear the new disappearing timer');
  const odd = next(sa, 'disappearing_changed', () => true, 800);
  sa.emit('set_disappearing', { recipientId: B.id, seconds: 7 });
  ok(!(await odd), 'timer only accepts the listed values');
  const outsiderTimer = next(sb, 'disappearing_changed', () => true, 800);
  sc.emit('set_disappearing', { recipientId: B.id, seconds: 86400 });
  ok(!(await outsiderTimer), 'non-friend cannot set a timer on someone’s chat');
  const histT = next(sa, 'history', (h) => h.recipientId === B.id);
  sa.emit('get_history', { recipientId: B.id });
  ok((await histT)?.disappearSeconds === 3600, 'history carries the chat timer');
  const dmP = next(sb, 'message', (m) => m.tempId === 'dis1');
  sa.emit('message', { message: 'vanishing', recipientId: B.id, tempId: 'dis1' });
  const dmsg = await dmP;
  const ttl = dmsg?.expiresAt ? (new Date(dmsg.expiresAt) - Date.now()) / 1000 : 0;
  ok(ttl > 3500 && ttl <= 3601, 'new message expires after the timer', `ttl ${Math.round(ttl)}s`);
  execSync(`docker exec haki_db psql -U user -d haki_db -c "update messages set \\"expiresAt\\" = now() - interval '1 minute' where id = ${dmsg.id}"`);
  const purged = next(sb, 'message_deleted', (d) => d.messageId === dmsg.id, 8000);
  ok(!!(await purged), 'expired message is deleted and both phones are told');
  ok(execSync(`docker exec haki_db psql -U user -d haki_db -tAc "select count(*) from messages where id=${dmsg.id}"`).toString().trim() === '0', 'expired message is gone from the database');
  const timerOff = next(sb, 'disappearing_changed');
  sb.emit('set_disappearing', { recipientId: A.id, seconds: 0 });
  ok((await timerOff)?.seconds === 0, 'either person can turn the timer off');

  // --- View once ---
  const voForm = new FormData();
  voForm.append('file', new Blob([new Uint8Array([1, 2, 3, 4])]), 'enc.bin');
  const up = await fetch(API + '/users/upload', { method: 'POST', headers: { Authorization: `Bearer ${A.token}` }, body: voForm }).then((r) => r.json());
  const vo = next(sb, 'message', (m) => m.tempId === 'vo1');
  sa.emit('message', { message: 'x', recipientId: B.id, tempId: 'vo1', attachmentUrl: up.attachmentUrl, attachmentType: 'image', viewOnce: true });
  const voMsg = await vo;
  ok(voMsg?.viewOnce === true && !voMsg.viewedAt, 'view-once photo arrives marked view once');
  ok((await fetch(API + up.attachmentUrl)).status === 200, 'view-once file downloadable before opening');
  const selfOpen = next(sa, 'message_viewed', () => true, 800);
  sa.emit('open_view_once', { messageId: voMsg.id });
  ok(!(await selfOpen), 'sender cannot open their own view-once');
  const viewedA = next(sa, 'message_viewed', (d) => d.id === voMsg.id);
  sb.emit('open_view_once', { messageId: voMsg.id });
  const viewed = await viewedA;
  ok(viewed?.viewedAt && !viewed.attachmentUrl, 'sender sees it was opened; the link is gone');
  await sleep(200);
  ok((await fetch(API + up.attachmentUrl)).status === 404, 'view-once file is deleted from the server');
  const loungeVo = next(sa, 'message', (m) => m.tempId === 'vo2');
  sa.emit('message', { message: 'x', tempId: 'vo2', attachmentUrl: '/uploads/messages/none.bin', attachmentType: 'image', viewOnce: true });
  ok((await loungeVo)?.viewOnce === false, 'view once is ignored outside private chats');

  // --- Usernames ---
  const handle = `ali_${run}`;
  ok((await http('PUT', '/users/me/handle', A.token, { handle: 'Ab', sealed: 's' })).status === 400, 'too-short username rejected');
  ok((await http('PUT', '/users/me/handle', A.token, { handle: `@${handle}`, sealed: 'sealed-copy' })).status === 200, 'username saved');
  ok((await http('PUT', '/users/me/handle', C.token, { handle, sealed: 'x' })).status === 409, 'taken username → 409');
  const meH = await http('GET', '/users/me', A.token);
  ok(meH.data.handleSealed === 'sealed-copy' && !('handleHash' in meH.data), '/users/me returns only the sealed copy');
  ok(!JSON.stringify((await http('GET', '/users/friends', B.token)).data).includes('sealed-copy'), 'friends list never includes usernames');
  const stored = execSync(`docker exec haki_db psql -U user -d haki_db -tAc "select \\"handleHash\\" from users where id=${A.id}"`).toString().trim();
  ok(stored.length === 64 && !stored.includes(handle), 'server stores only a hash of the username');
  const byHandle = await http('POST', '/users/friends/requests', C.token, { email: `@${handle.toUpperCase()}` });
  ok(byHandle.status === 201, 'friend request by @username works (any case)', `status ${byHandle.status}`);
  await http('DELETE', '/users/me/handle', A.token);
  ok((await http('POST', '/users/friends/requests', B.token, { email: `@${handle}` })).status === 404, 'removed username no longer finds anyone');

  // --- Reports ---
  const rep = await http('POST', '/reports', B.token, { messageId: mB.id, reason: 'spam', content: 'hello bob', note: 'test' });
  ok(rep.status === 201, 'recipient can report a message');
  ok((await http('POST', '/reports', A.token, { messageId: mB.id, reason: 'spam' })).status === 400, 'cannot report your own message');
  ok((await http('POST', '/reports', C.token, { messageId: mB.id, reason: 'spam' })).status === 404, 'outsider cannot report a private message');
  ok((await http('POST', '/reports', B.token, { messageId: mB.id, reason: 'nope' })).status === 400, 'unknown reason rejected');

  // --- Bans (admin) ---
  execSync(`docker exec haki_db psql -U user -d haki_db -c "update users set role='admin' where username='${A.username}'"`);
  const admin = (await http('POST', '/auth/login', null, { username: A.username, password: 'password123' })).data.access_token;
  const kicked = new Promise((res) => sc.once('disconnect', () => res(true)));
  const ban = await http('PATCH', `/admin/users/${C.id}/ban`, admin);
  ok(ban.status === 200, 'admin can ban');
  ok(await Promise.race([kicked, sleep(2000).then(() => false)]), 'banned user’s live socket is disconnected');
  ok((await http('POST', '/auth/login', null, { username: C.username, password: 'password123' })).status === 403, 'banned user cannot log in');
  ok((await http('GET', '/users/me', C.token)).status === 401, 'banned user’s existing token rejected');
  ok((await http('GET', '/admin/stats', B.token)).status === 403, 'non-admin cannot use the admin API');
  ok((await http('PATCH', `/admin/users/${A.id}/ban`, B.token)).status === 403, 'non-admin cannot ban');
  const stats = await http('GET', '/admin/stats', admin);
  ok(stats.status === 200 && stats.data.usersCount >= 3, 'dashboard stats endpoint works');

  // --- Dashboard: overview, people, Lounge moderation ---
  const ov = await http('GET', '/admin/overview?tz=Europe/Berlin', admin);
  ok(ov.status === 200 && ov.data.totals.users >= 3 && Array.isArray(ov.data.heatmap), 'overview endpoint works');
  ok((await http('GET', "/admin/overview?tz=x';drop", admin)).data.tz === 'UTC', 'bad time zone falls back to UTC');
  ok((await http('GET', '/admin/overview', B.token)).status === 403, 'non-admin cannot read the overview');
  const people = await http('GET', '/admin/users', admin);
  ok(people.data.find((u) => u.id === A.id)?.messages > 0, 'people list includes message counts');
  const lounge = await http('GET', '/admin/lounge?limit=5', admin);
  const loungeMsg = lounge.data.find((m) => m.senderId === A.id);
  ok(!!loungeMsg && !lounge.data.some((m) => m.recipientId), 'admin sees recent Lounge messages');
  const gone = next(sb, 'message_deleted');
  ok((await http('DELETE', `/admin/lounge/${loungeMsg.id}`, admin)).status === 200, 'admin can delete a Lounge message');
  ok((await gone)?.messageId === loungeMsg.id, 'Lounge delete reaches open apps');
  const dm = msgs[0]; // still exists: only the newest was deleted above
  ok((await http('DELETE', `/admin/lounge/${dm.id}`, admin)).status === 404, 'admin cannot delete a private message');
  ok(execSync(`docker exec haki_db psql -U user -d haki_db -tAc "select count(*) from messages where id=${dm.id}"`).toString().trim() === '1', 'private message is untouched');
  const reps = await http('GET', '/admin/reports', admin);
  const mine = reps.data.find((r) => r.id === rep.data.id);
  ok(mine && mine.content === 'hello bob' && mine.chat === 'direct' && mine.reportedId === A.id, 'admin sees the report with the reporter’s text');
  ok((await http('GET', '/admin/reports', B.token)).status === 403, 'non-admin cannot read reports');
  const repGone = next(sb, 'message_deleted', (d) => d.messageId === mB.id);
  ok((await http('DELETE', `/admin/reports/${rep.data.id}/message`, admin)).status === 200, 'admin can delete a reported message');
  ok(!!(await repGone), 'deleted reported message disappears live');
  ok(!(await http('GET', '/admin/reports', admin)).data.some((r) => r.id === rep.data.id), 'report is closed after the delete');
  ok((await http('GET', '/admin/overview', admin)).data.totals.openReports >= 0, 'overview counts open reports');

  // --- Tier 2/3: profile hardening, birthdays, backup ---
  await http('PATCH', '/users/profile', B.token, { role: 'admin', displayName: 'Bob' });
  ok((await http('GET', '/users/me', B.token)).data.role === 'user', 'profile update cannot change role');
  ok((await http('PATCH', '/users/profile', A.token, { birthday: '13-40' })).status === 400, 'bad birthday rejected');
  await http('PATCH', '/users/profile', A.token, { birthday: '04-23' });
  ok((await http('GET', '/users/friends', B.token)).data.find((f) => f.id === A.id)?.birthday === '04-23', 'friends see the birthday');
  ok('handleSealed' in (await http('PATCH', '/users/profile', A.token, { bio: 'hi' })).data, 'profile update keeps the sealed username in its reply');
  await http('PUT', '/users/me/backup', A.token, { sealed: 'SEALED-BLOB' });
  const bk = await http('GET', '/users/me/backup', A.token);
  ok(bk.data.sealed === 'SEALED-BLOB' && !!bk.data.at, 'encrypted app-data backup round-trips');
  ok(!('backupSealed' in (await http('GET', '/users/me', A.token)).data), 'backup is not in the profile');

  // --- Group read receipts + unread synced across devices ---
  const grp = (await http('POST', '/groups', A.token, { name: 'Readers ' + run, memberIds: [B.id] })).data;
  const sb2 = await connect(B.token);
  const gm = next(sb, 'message', (m) => m.tempId === 'g1');
  sa.emit('message', { message: 'group hi', groupId: grp.id, tempId: 'g1' });
  const gmsg = await gm;
  ok((await http('GET', '/groups', B.token)).data.find((g) => g.id === grp.id)?.unreadCount === 1, 'group unread count comes from the server');
  const seen = next(sa, 'group_read', (d) => d.groupId === grp.id);
  const synced = next(sb2, 'read_sync', (d) => d.groupId === grp.id);
  sb.emit('mark_read', { groupId: grp.id });
  const seenEvt = await seen;
  ok(seenEvt && seenEvt.userId === B.id && seenEvt.lastReadId >= gmsg.id, 'sender hears who read the group message');
  ok(!!(await synced), 'reading on one device clears unread on the other');
  ok((await http('GET', '/groups', B.token)).data.find((g) => g.id === grp.id)?.unreadCount === 0, 'group unread is 0 after reading');
  const grpHist = next(sa, 'history', (h) => h.groupId === grp.id);
  sa.emit('get_history', { groupId: grp.id });
  ok((await grpHist)?.readers?.some((r) => r.userId === B.id && r.lastReadId >= gmsg.id), 'group history includes readers for "Seen by"');
  const dmSync = next(sb2, 'read_sync', (d) => d.friendId === A.id);
  sb.emit('mark_read', { friendId: A.id });
  ok(!!(await dmSync), 'private chat read syncs to other devices');

  // --- Group calls (mesh signalling) ---
  const ack = (sock, ev, data) => new Promise((r) => sock.emit(ev, data, r));
  const ringB = next(sb, 'group_call', (d) => d.groupId === grp.id && d.participants.includes(A.id));
  ok((await ack(sa, 'gc_join', { groupId: grp.id })).participants.length === 0, 'first person starts the group call');
  ok(!!(await ringB), 'members hear that a group call started');
  ok(JSON.stringify((await ack(sb2, 'gc_join', { groupId: grp.id })).participants) === JSON.stringify([A.id]), 'joiner gets who is already in the call');
  const sig = next(sa, 'gc_signal', (d) => d.from === B.id);
  sb2.emit('gc_signal', { groupId: grp.id, to: A.id, signal: { type: 'offer', sdp: 'x' } });
  ok((await sig)?.signal?.type === 'offer', 'offers are relayed between participants');
  const D = await makeUser('dave');
  const sd = await connect(D.token);
  ok(!!(await ack(sd, 'gc_join', { groupId: grp.id })).error, 'non-members cannot join a group call');
  const left = next(sa, 'group_call', (d) => d.groupId === grp.id && !d.participants.includes(B.id));
  sb2.disconnect();
  ok(!!(await left), 'closing the app leaves the call');
  await ack(sa, 'gc_leave', { groupId: grp.id });
  ok((await ack(sa, 'gc_state', { groupId: grp.id })).participants.length === 0, 'call ends when the last person leaves');

  // --- Devices: list, remove ---
  const t2 = (await http('POST', '/auth/login', null, { username: D.username, password: 'password123', deviceName: 'iPad', platform: 'ios' })).data.access_token;
  const devs = (await http('GET', '/auth/sessions', D.token)).data;
  const ipad = devs.find((d) => d.name === 'iPad');
  ok(devs.length === 2 && devs.some((d) => d.current) && !!ipad, 'device list shows each sign-in and marks this one');
  const sIpad = await connect(t2);
  const ipadOff = next(sIpad, 'disconnect', () => true);
  ok((await http('DELETE', `/auth/sessions/${ipad.id}`, D.token)).status === 200, 'can remove another device');
  ok(!!(await ipadOff), 'removed device is disconnected live');
  ok((await http('GET', '/users/me', t2)).status === 401, 'removed device’s token stops working');
  ok((await http('DELETE', `/auth/sessions/${ipad.id}`, B.token)).status === 404, 'cannot remove someone else’s device');

  // --- Two-step login (TOTP) ---
  const totp = (secret, at = Date.now()) => {
    const A32 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    const bits = [...secret].map((c) => A32.indexOf(c).toString(2).padStart(5, '0')).join('');
    const key = Buffer.from(bits.match(/.{8}/g).map((b) => parseInt(b, 2)));
    const ctr = Buffer.alloc(8); ctr.writeBigUInt64BE(BigInt(Math.floor(at / 30000)));
    const h = require('crypto').createHmac('sha1', key).update(ctr).digest();
    const o = h[h.length - 1] & 15;
    return String((h.readUInt32BE(o) & 0x7fffffff) % 1e6).padStart(6, '0');
  };
  const setup = (await http('POST', '/auth/2fa/setup', D.token)).data;
  ok(/^otpauth:\/\/totp\//.test(setup.uri), 'two-step setup returns an authenticator link');
  ok((await http('POST', '/auth/2fa/enable', D.token, { code: '000000' })).status === 400, 'wrong code does not turn it on');
  ok((await http('POST', '/auth/2fa/enable', D.token, { code: totp(setup.secret) })).data.enabled === true, 'right code turns two-step on');
  const noCode = await http('POST', '/auth/login', null, { username: D.username, password: 'password123' });
  ok(noCode.status === 401 && noCode.data.twoFactor === true, 'login asks for the code', JSON.stringify(noCode.data));
  ok((await http('POST', '/auth/login', null, { username: D.username, password: 'password123', code: '123456' })).status === 401, 'wrong code is refused');
  ok(!!(await http('POST', '/auth/login', null, { username: D.username, password: 'password123', code: totp(setup.secret) })).data.access_token, 'password + code signs in');
  ok((await http('POST', '/auth/2fa/disable', D.token, { code: totp(setup.secret) })).data.enabled === false, 'can turn two-step off with a code');

  // --- Linking a device by code ---
  const pub = Buffer.alloc(32, 7).toString('base64');
  const link = (await http('POST', '/auth/link', null, { pub, name: 'Test iPad', platform: 'ios' })).data;
  ok(/^[A-Z2-9]{8}$/.test(link.code) && !!link.secret, 'new device gets a link code');
  ok((await http('GET', `/auth/link/${link.code}?secret=${link.secret}`)).data.status === 'waiting', 'link waits for approval');
  ok((await http('GET', `/auth/link/${link.code}?secret=wrong`)).status === 404, 'polling needs the device’s secret');
  ok((await http('GET', `/auth/link/${link.code}/peek`, D.token)).data.pub === pub, 'phone reads the new device’s key');
  ok((await http('POST', `/auth/link/${link.code}/approve`, D.token, { sealed: 'SEALED-KEY', pub: Buffer.alloc(32, 9).toString('base64') })).status === 201, 'phone approves the link');
  const done = (await http('GET', `/auth/link/${link.code}?secret=${link.secret}`)).data;
  ok(done.status === 'approved' && done.sealed === 'SEALED-KEY' && done.username === D.username, 'new device receives the sealed key');
  ok((await http('GET', '/users/me', done.access_token)).data.id === D.id, 'linked device is signed in');
  ok((await http('GET', '/auth/sessions', D.token)).data.some((d) => d.kind === 'linked' && d.name === 'Test iPad'), 'linked device shows in the list');
  ok((await http('GET', `/auth/link/${link.code}?secret=${link.secret}`)).status === 404, 'a link code works once');

  // --- Push tokens: VoIP (CallKit) and Android ---
  ok((await http('POST', '/push/devices', D.token, { token: 'ab'.repeat(32), platform: 'voip' })).data.ok === true, 'VoIP token registers');
  ok((await http('POST', '/push/devices', D.token, { token: 'fcm:Token_abc-123456789012345', platform: 'android' })).data.ok === true, 'Android FCM token registers');
  ok((await http('POST', '/push/devices', D.token, { token: 'x', platform: 'fax' })).data.ok === false, 'unknown push platform is refused');

  // --- A phone woken by CallKit still gets the offer ---
  sb.emit('call_user', { to: A.id, offer: { type: 'offer', sdp: 'x' } });
  await sleep(300);
  const wokeA = await connect(A.token);
  const lateOffer = await next(wokeA, 'call_offer', (d) => Number(d.from) === B.id, 2000);
  ok(!!lateOffer, 'a phone that connects during the ring gets the call offer');
  sb.emit('call_end', { to: A.id });
  await sleep(300);
  const later = await connect(A.token);
  ok(!(await next(later, 'call_offer', () => true, 1200)), 'no stale offer after the call ended');
  wokeA.disconnect(); later.disconnect();

  // --- Sign-up control, invites, audit log ---
  ok((await http('PUT', '/admin/access/mode', B.token, { mode: 'closed' })).status === 403, 'non-admin cannot change sign-ups');
  await http('PUT', '/admin/access/mode', admin, { mode: 'invite' });
  ok((await http('GET', '/auth/signup')).data.mode === 'invite', 'app can see that an invite is needed');
  const reg1 = await http('POST', '/auth/register', null, { username: `inv_${run}`, email: `inv_${run}@t.local`, password: 'password123' });
  ok(reg1.status === 403, 'invite mode refuses sign-up without a code');
  const inv = (await http('POST', '/admin/invites', admin, { maxUses: 1, days: 7, note: 'smoke' })).data;
  ok((await http('POST', '/auth/register', null, { username: `inv_${run}`, email: `inv_${run}@t.local`, password: 'password123', inviteCode: inv.code.toLowerCase() })).status === 201, 'valid invite code lets someone join');
  ok((await http('POST', '/auth/register', null, { username: `inv2_${run}`, email: `inv2_${run}@t.local`, password: 'password123', inviteCode: inv.code })).status === 403, 'a used-up code is refused');
  await http('PUT', '/admin/access/mode', admin, { mode: 'closed' });
  ok((await http('POST', '/auth/register', null, { username: `cl_${run}`, email: `cl_${run}@t.local`, password: 'password123' })).status === 403, 'closed mode refuses sign-ups');
  await http('PUT', '/admin/access/mode', admin, { mode: 'open' });
  ok((await http('DELETE', `/admin/invites/${inv.id}`, admin)).status === 200, 'admin can revoke an invite');
  const audit = (await http('GET', '/admin/audit', admin)).data;
  ok(['signup.mode', 'invite.create', 'invite.revoke', 'user.ban', 'lounge.delete', 'message.delete'].every((a) => audit.some((r) => r.action === a && r.admin === A.username)),
    'audit log records who did each action');
  ok((await http('GET', '/admin/audit', B.token)).status === 403, 'non-admin cannot read the audit log');
  const dev = (await http('GET', '/admin/devices', admin)).data;
  ok(dev.totals?.active > 0 && dev.totals.online >= 1 && Array.isArray(dev.platforms) && dev.daily?.length === 14, 'device insights: totals, platforms, 14 days');
  ok(dev.recent?.some((r) => r.username === A.username) && dev.platforms.every((p) => !('ids' in p)), 'device insights list recent devices without raw ids per platform');
  ok((await http('GET', '/admin/devices', B.token)).status === 403, 'non-admin cannot read device insights');

  // --- Spam guard + signals (last: it throttles B) ---
  const tooFast = next(sb, 'message_error', (e) => /too fast/.test(e.error), 4000);
  for (let i = 0; i < 35; i++) sb.emit('message', { message: 'spam ' + i, recipientId: A.id, tempId: 'sp' + i });
  ok(!!(await tooFast), 'sending too fast is slowed down');
  await sleep(2000); // let the queued sends land
  const sig2 = (await http('GET', '/admin/signals', admin)).data;
  const bSig = sig2.find((u) => u.id === B.id);
  ok(bSig && bSig.signals.some((x) => x.kind === 'ratelimit') && bSig.signals.some((x) => x.kind === 'burst'), 'spam signals flag the sender', JSON.stringify(bSig?.signals));
  ok(!JSON.stringify(sig2).includes('spam 1'), 'signals contain no message content');
  sd.disconnect();

  sa.disconnect(); sb.disconnect();
  restoreSignup();
  console.log(`\n${failures === 0 ? 'ALL PASSED' : failures + ' FAILED'}`);
  process.exit(failures ? 1 : 0);
})().catch((e) => { restoreSignup(); console.error('CRASH', e); process.exit(2); });
