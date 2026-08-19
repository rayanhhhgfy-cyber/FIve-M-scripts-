let PD = {}, CS = 'home', TT = null, CT = [], CV = [], MS = null;
let dialedNumber = '', calcStr = '', calcOp = null, calcPrev = null, calcClear = false;
let swActive = false, swTime = 0, swLaps = [], swInterval = null;
let timerActive = false, timerRemaining = 300, timerInterval = null;
let calViewDate = new Date(), calEvents = [];
let callActive = false, callTimerInterval = null, callSeconds = 0;

function $(id) { return document.getElementById(id); }

function showScreen(id) {
    document.querySelectorAll('#app-container > .screen').forEach(s => s.classList.remove('active'));
    const sc = $(id); if (sc) sc.classList.add('active');
    CS = id;
    if (MS) { MS.getTracks().forEach(t => t.stop()); MS = null; }
}

function dialog(title, fields, onConfirm, extra) {
    const ov = $('dialog-overlay');
    ov.classList.add('active');
    $('dialog-title').textContent = title;
    const fb = $('dialog-fields');
    fb.innerHTML = fields.map((f,i) => {
        if (f.type === 'select') {
            let opts = (f.options||[]).map(o => `<option value="${o.value}">${o.label}</option>`).join('');
            return `<select id="df-${i}">${opts}</select>`;
        }
        if (f.type === 'textarea') return `<textarea id="df-${i}" placeholder="${f.placeholder||''}" rows="${f.rows||3}">${f.value||''}</textarea>`;
        return `<input id="df-${i}" placeholder="${f.placeholder||''}" type="${f.type||'text'}" value="${f.value||''}" ${f.type==='number'?'inputmode="numeric"':''}>`;
    }).join('');
    ov.querySelector('#dialog-cancel').onclick = () => ov.classList.remove('active');
    ov.querySelector('#dialog-confirm').onclick = () => {
        const vals = fields.map((_,i) => $(`df-${i}`) ? $(`df-${i}`).value : '');
        ov.classList.remove('active');
        if (onConfirm) onConfirm(vals);
    };
    if (extra && extra.cancelText) ov.querySelector('#dialog-cancel').textContent = extra.cancelText;
    if (extra && extra.confirmText) ov.querySelector('#dialog-confirm').textContent = extra.confirmText;
}

// ============ NUI MESSAGE HANDLER ============
window.addEventListener('message', function(event) {
    const d = event.data; if (!d) return;
    if (d.type === 'open') {
        PD = d; renderHome(); showScreen('screen-home');
        if (d.data && d.data.playerCid) $('settings-cid').textContent = 'CID: ' + d.data.playerCid;
        if (d.data && d.data.name) $('settings-name').textContent = d.data.name;
        updateTime_();
    }
    if (d.type === 'close') { if (MS) { MS.getTracks().forEach(t => t.stop()); MS = null; } }
    if (d.type === 'contactAdded') { CT.push(d.contact); renderContacts(); renderPhoneContacts(); }
    if (d.type === 'newMessage') {
        if (CS === 'screen-messages' && TT && TT === d.msg.sender_cid) {
            const c = $('thread-messages');
            c.innerHTML += `<div class="msg-bubble msg-received">${escHtml(d.msg.content)}<div class="msg-time">${d.msg.created_at||'Just now'}</div></div>`;
            c.scrollTop = c.scrollHeight;
        } else { renderConversations(); }
    }
    if (d.type === 'bankBalance') { $('bank-amount').textContent = '$'+(d.bank||0).toLocaleString(); $('cash-amount').textContent = '$'+(d.cash||0).toLocaleString(); $('wallet-card-amount').textContent = '$'+(d.bank||0).toLocaleString(); }
    if (d.type === 'transferComplete') { $('bank-amount').textContent = '$'+(d.balance||0).toLocaleString(); $('transfer-target').value=''; $('transfer-amount').value=''; }
    if (d.type === 'loadPhotos') {
        const g = $('photos-grid'); const cg = $('camera-gallery');
        if (!d.photos||d.photos.length===0) { g.innerHTML='<div class="photo-empty">No photos yet</div>'; return; }
        g.innerHTML = d.photos.map(p => `<div class="photo-item" style="position:relative"><img src="${p.image_data||'https://via.placeholder.com/150/1c1c1e/fff?text=📸'}" style="width:100%;height:100%;object-fit:cover"><button class="delete-photo" data-id="${p.id}"><i class="fas fa-times"></i></button></div>`).join('');
        g.querySelectorAll('.delete-photo').forEach(b => b.addEventListener('click', e => { e.stopPropagation(); fetch('https://'+GetRN()+'/deletePhoto',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({id:parseInt(b.dataset.id)})}); b.closest('.photo-item').remove(); }));
    }
    if (d.type === 'loadNotes') { renderNotes(d.notes||[]); }
    if (d.type === 'loadCalendarEvents') { calEvents = d.events||[]; if (CS==='screen-calendar') renderCalendar(); }
    if (d.type === 'loadWeather') {
        if (d.icon) $('weather-icon').textContent = d.icon;
        if (d.temp) $('weather-temp').textContent = d.temp+'°';
        if (d.label) $('weather-desc').textContent = d.label;
        if (d.humidity) $('weather-humidity').textContent = d.humidity+'%';
        if (d.wind) $('weather-wind').textContent = d.wind;
    }
    if (d.type === 'loadTweets') { renderTweets(d.tweets||[]); }
    if (d.type === 'loadBlackChatRooms') { renderBCRooms(d.rooms||[]); }
    if (d.type === 'loadBlackChatMessages') {
        $('bc-room-name').textContent = d.roomId;
        bcMembers = d.members||[];
        $('bc-member-count').textContent = bcMembers.length;
        renderBCMessages(d.messages||[]);
        if (!$('bc-members-panel').classList.contains('hidden')) renderBCMembers();
    }
    if (d.type === 'loadBCMembers') { bcMembers = d.members||[]; $('bc-member-count').textContent = bcMembers.length; renderBCMembers(); }
    if (d.type === 'blackChatMessage') {
        if (!document.getElementById('bc-chat').classList.contains('hidden') && $('bc-room-name').textContent === d.roomId) {
            addBCMessage(d);
        }
    }
    if (d.type === 'incomingCall') {
        $('inc-call-name').textContent = d.callerName||d.caller;
        $('#incoming-call').classList.remove('hidden');
    }
    if (d.type === 'callConnected') {
        $('#incoming-call').classList.add('hidden');
        $('#active-call').classList.remove('hidden');
        $('ac-name').textContent = d.peerName||d.peer;
        callActive = true; callSeconds = 0;
        if (callTimerInterval) clearInterval(callTimerInterval);
        callTimerInterval = setInterval(() => { callSeconds++; let m=String(Math.floor(callSeconds/60)).padStart(2,'0'), s=String(callSeconds%60).padStart(2,'0'); $('ac-timer').textContent = m+':'+s; }, 1000);
    }
    if (d.type === 'callEnded') {
        $('#incoming-call').classList.add('hidden');
        $('#active-call').classList.add('hidden');
        callActive = false; if (callTimerInterval) { clearInterval(callTimerInterval); callTimerInterval = null; }
    }
    if (d.type === 'callMissed') { /* could notify */ }
    if (d.type === 'callHistory') { renderRecents(d.history||[]); }
    if (d.type === 'loadVoicemails') { renderVoicemails(d.voicemails||[]); }
    if (d.type === 'contactShared') {
        dialog('Contact Shared', [
            {id:'share_name',placeholder:'Name',value:d.contact.name},
            {id:'share_number',placeholder:'Number',value:d.contact.number},
        ], vals => {
            fetch('https://'+GetRN()+'/addContact',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({name:vals[0],number:vals[1],targetCid:d.contact.cid})});
        }, {confirmText:'Save Contact'});
    }
    if (d.type === 'speakerChanged') { $('setting-speaker').checked = d.enabled; }
    if (d.type === 'updateLocation') {
        $('maps-coords').textContent = `📍 ${(d.lat||0).toFixed(4)}, ${(d.lon||0).toFixed(4)}`;
    }
});

// ============ HOME ============
function renderHome() {
    const cfg = PD.config||{}, apps = cfg.apps||[], dockApps = cfg.dockApps||[];
    const grid = $('home-apps'); grid.innerHTML = '';
    apps.forEach(a => {
        const div = document.createElement('div');
        div.className = 'app-icon'; div.dataset.app = a.id;
        div.innerHTML = `<i style="background:${a.color}"><i class="${a.icon}"></i></i><span>${a.label}</span>`;
        div.addEventListener('click', () => openApp(a.id));
        grid.appendChild(div);
    });
    const dock = $('home-dock'); dock.innerHTML = '';
    dockApps.forEach(id => {
        const a = apps.find(x => x.id === id); if (!a) return;
        const div = document.createElement('div');
        div.className = 'app-icon'; div.dataset.app = a.id;
        div.innerHTML = `<i style="background:${a.color}"><i class="${a.icon}"></i></i></div>`;
        div.addEventListener('click', () => openApp(a.id));
        dock.appendChild(div);
    });
    const now = new Date();
    const dateStr = now.toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric' });
    $('home-date').textContent = dateStr;
}

function openApp(id) {
    const map = {
        phone:'screen-phone', messages:'screen-messages', contacts:'screen-contacts',
        facetime:'screen-facetime', banking:'screen-banking', photos:'screen-photos',
        camera:'screen-camera', weather:'screen-weather', maps:'screen-maps',
        music:'screen-music', social:'screen-social', blackchat:'screen-blackchat',
        browser:'screen-browser', notes:'screen-notes', calendar:'screen-calendar',
        clock:'screen-clock', calculator:'screen-calculator', wallet:'screen-wallet',
        settings:'screen-settings', appstore:'screen-appstore'
    };
    const screen = map[id];
    if (!screen) return;
    switch(id) {
        case 'phone': switchPhoneTab('keypad'); break;
        case 'contacts': renderContacts(); break;
        case 'messages': renderConversations(); break;
        case 'banking': fetch('https://'+GetRN()+'/getBankBalance',{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'}); break;
        case 'camera': openCamera(); break;
        case 'photos': fetch('https://'+GetRN()+'/getPhotos',{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'}); break;
        case 'weather': fetch('https://'+GetRN()+'/getWeather',{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'}); break;
        case 'social': fetch('https://'+GetRN()+'/getTweets',{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'}); break;
        case 'blackchat': fetch('https://'+GetRN()+'/getBlackChatRooms',{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'}); break;
        case 'notes': fetch('https://'+GetRN()+'/getNotes',{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'}); break;
        case 'calendar': renderCalendar(); fetch('https://'+GetRN()+'/getCalendarEvents',{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'}); break;
        case 'clock': switchClockTab('alarm'); break;
        case 'facetime': renderFaceTime(); break;
        case 'maps': fetch('https://'+GetRN()+'/getCurrentLocation',{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'}).then(r=>r.json()).then(p=>{$('maps-coords').textContent=`📍 ${(p.lat||0).toFixed(4)}, ${(p.lon||0).toFixed(4)}`;}); break;
    }
    showScreen(screen);
}

// ============ PHONE / DIALER ============
document.querySelectorAll('.key').forEach(k => k.addEventListener('click', () => { dialedNumber += k.dataset.key; $('dial-number').textContent = dialedNumber; }));
document.getElementById('backspace-btn').addEventListener('click', () => { dialedNumber = dialedNumber.slice(0,-1); $('dial-number').textContent = dialedNumber; });
document.getElementById('call-btn').addEventListener('click', () => { if (dialedNumber) fetch('https://'+GetRN()+'/dialNumber',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({number:dialedNumber})}); });
document.querySelectorAll('.phone-tab').forEach(t => t.addEventListener('click', () => switchPhoneTab(t.dataset.tab)));

function switchPhoneTab(tab) {
    document.querySelectorAll('.phone-tab').forEach(t => t.classList.remove('active'));
    document.querySelector(`.phone-tab[data-tab="${tab}"]`).classList.add('active');
    document.querySelectorAll('.phone-panel').forEach(p => p.classList.remove('active'));
    const panel = $(`phone-${tab}`); if (panel) panel.classList.add('active');
    if (tab === 'recents') fetch('https://'+GetRN()+'/getCallHistory',{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'});
    if (tab === 'voicemail') fetch('https://'+GetRN()+'/getVoicemails',{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'});
    if (tab === 'contacts') { if (!CT.length) fetchContacts(); renderPhoneContacts(); }
}

function fetchContacts() {
    if (PD.data) CT = PD.data.contacts||[];
}

function renderPhoneContacts() {
    const c = $('phone-contacts'); c.innerHTML = '';
    if (!CT.length) { c.innerHTML='<div style="padding:20px;text-align:center;color:#8e8e93">No contacts</div>'; return; }
    CT.forEach(ct => {
        const d = document.createElement('div'); d.className = 'list-item';
        d.innerHTML = `<div class="avatar" style="background:#007aff">${(ct.name||'?')[0].toUpperCase()}</div><div class="info"><div class="name">${ct.name||'Unknown'}</div><div class="sub">${ct.number||''}</div></div>`;
        d.addEventListener('click', () => { dialedNumber = ct.number||ct.cid||''; $('dial-number').textContent = dialedNumber; switchPhoneTab('keypad'); });
        c.appendChild(d);
    });
}

function renderRecents(history) {
    const c = $('phone-recents'); c.innerHTML = '';
    if (!history||!history.length) { c.innerHTML='<div style="padding:20px;text-align:center;color:#8e8e93">No recent calls</div>'; return; }
    history.forEach(h => {
        const d = document.createElement('div'); d.className = 'call-item';
        const isOut = h.caller_cid === (PD.data&&PD.data.playerCid);
        const icon = isOut ? 'fa-phone-out' : 'fa-phone-in';
        const color = h.status === 'missed' || h.status === 'rejected' ? '#ff3b30' : '#34c759';
        d.innerHTML = `<div class="call-icon" style="background:${color}22;color:${color}"><i class="fas ${icon}"></i></div><div class="call-info"><div class="call-name">${h.caller_name||h.caller_cid||h.receiver_cid||'Unknown'}</div><div class="call-meta">${h.status} · ${h.duration?s+'s':''}</div></div>`;
        c.appendChild(d);
    });
}

function renderVoicemails(vms) {
    const c = $('phone-voicemail'); c.innerHTML = '';
    if (!vms||!vms.length) { c.innerHTML='<div style="padding:20px;text-align:center;color:#8e8e93">No voicemails</div>'; return; }
    vms.forEach(v => {
        const d = document.createElement('div'); d.className = 'call-item';
        d.innerHTML = `<div class="call-icon" style="background:#ff9f0a22;color:#ff9f0a"><i class="fas fa-tape"></i></div><div class="call-info"><div class="call-name">${v.caller_name||v.caller_cid||'Unknown'}</div><div class="call-meta">${v.duration||0}s · ${v.created_at||''}</div></div>`;
        c.appendChild(d);
    });
}

document.getElementById('inc-answer').addEventListener('click', () => { fetch('https://'+GetRN()+'/answerCall',{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'}); });
document.getElementById('inc-decline').addEventListener('click', () => { fetch('https://'+GetRN()+'/rejectCall',{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'}); });
document.getElementById('ac-end').addEventListener('click', () => { fetch('https://'+GetRN()+'/endCall',{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'}); });
document.getElementById('ac-mute').addEventListener('click', function() { this.classList.toggle('active'); });
document.getElementById('ac-speaker').addEventListener('click', function() { this.classList.toggle('active'); fetch('https://'+GetRN()+'/setSpeaker',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({enabled:this.classList.contains('active')})}); });

document.getElementById('phone-add-btn').addEventListener('click', () => {
    dialog('Add Contact', [{id:'name',placeholder:'Full Name'},{id:'number',placeholder:'Phone Number'},{id:'cid',placeholder:'CID (optional)'}], vals => {
        fetch('https://'+GetRN()+'/addContact',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({name:vals[0],number:vals[1],targetCid:vals[2]})});
    });
});

// ============ CONTACTS ============
function renderContacts() {
    fetchContacts();
    const l = $('contacts-list'); l.innerHTML = '';
    const q = ($('contacts-search-input')||{value:''}).value.toLowerCase();
    let filtered = CT;
    if (q) filtered = CT.filter(c => (c.name||'').toLowerCase().includes(q)||(c.number||'').includes(q));
    if (!filtered.length) { l.innerHTML='<div style="padding:40px;text-align:center;color:#8e8e93">No contacts</div>'; return; }
    filtered.forEach(c => {
        const d = document.createElement('div'); d.className = 'list-item';
        d.innerHTML = `<div class="avatar" style="background:#007aff">${(c.name||'?')[0].toUpperCase()}</div><div class="info"><div class="name">${c.name||'Unknown'}</div><div class="sub">${c.number||''} ${c.cid?'| '+c.cid:''}</div></div><div class="actions"><button class="call-contact" data-num="${c.number||c.cid||''}"><i class="fas fa-phone"></i></button><button class="msg-contact" data-cid="${c.cid||''}" data-name="${c.name||''}"><i class="fas fa-comment"></i></button><button class="share-contact" data-id="${c.id}" data-name="${c.name||''}"><i class="fas fa-share"></i></button><button class="del-contact" data-id="${c.id}"><i class="fas fa-trash" style="color:#ff3b30"></i></button></div>`;
        d.querySelector('.call-contact').addEventListener('click', e => { e.stopPropagation(); const num=this.dataset.num; if(num){dialedNumber=num;$('dial-number').textContent=num;showScreen('screen-phone');switchPhoneTab('keypad');}});
        d.querySelector('.msg-contact').addEventListener('click', e => { e.stopPropagation(); openThread(b.dataset.cid, b.dataset.name); });
        d.querySelector('.share-contact').addEventListener('click', e => { e.stopPropagation(); shareContactDialog(parseInt(b.dataset.id), b.dataset.name); });
        d.querySelector('.del-contact').addEventListener('click', e => { e.stopPropagation(); fetch('https://'+GetRN()+'/deleteContact',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({id:parseInt(b.dataset.id)})}); d.remove(); });
        // Fix event listeners - use closures
        (function(ct) {
            d.querySelector('.call-contact').onclick = e => { e.stopPropagation(); const num=ct.number||ct.cid||''; if(num){dialedNumber=num;$('dial-number').textContent=num;showScreen('screen-phone');switchPhoneTab('keypad');}};
            d.querySelector('.msg-contact').onclick = e => { e.stopPropagation(); openThread(ct.cid, ct.name); };
            d.querySelector('.share-contact').onclick = e => { e.stopPropagation(); shareContactDialog(ct.id, ct.name); };
            d.querySelector('.del-contact').onclick = e => { e.stopPropagation(); fetch('https://'+GetRN()+'/deleteContact',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({id:ct.id})}); d.remove(); };
        })(c);
        l.appendChild(d);
    });
}

$('contacts-search-input').addEventListener('input', renderContacts);

function shareContactDialog(contactId, contactName) {
    dialog('Share Contact', [{id:'target',placeholder:'Enter recipient CID'}], vals => {
        if (vals[0]) fetch('https://'+GetRN()+'/shareContact',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({contactId:contactId,targetCid:vals[0]})});
    });
}

// ============ MESSAGES ============
function renderConversations() {
    const msgs = PD.data ? PD.data.messages||[] : [];
    const myCid = PD.data ? PD.data.playerCid||'' : '';
    const map = {};
    msgs.forEach(m => {
        const other = m.sender_cid === myCid ? m.receiver_cid : m.sender_cid;
        const otherName = m.sender_cid === myCid ? (m.receiver_first+' '+m.receiver_last).trim() : (m.sender_first+' '+m.sender_last).trim();
        if (!map[other]) map[other] = { cid:other, name:otherName||'Unknown', messages:[], unread:0 };
        map[other].messages.push(m);
        if (m.receiver_cid === myCid && !m.read) map[other].unread++;
    });
    CV = Object.values(map);
    const l = $('conversations-list'); l.classList.remove('hidden'); $('message-thread').classList.add('hidden');
    if (!CV.length) { l.innerHTML='<div style="padding:40px;text-align:center;color:#8e8e93">No messages</div>'; return; }
    l.innerHTML = CV.map(c => {
        const last = c.messages[c.messages.length-1];
        const init = c.name[0].toUpperCase()||'?';
        const unreadBadge = c.unread>0?`<div class="unread-badge">${c.unread}</div>`:'';
        return `<div class="conversation-item" data-cid="${c.cid}" data-name="${c.name}"><div class="avatar" style="background:#34c759">${init}</div><div class="preview"><div class="name">${c.name}</div><div class="text">${last?escHtml(last.content.substring(0,60)):''}</div></div>${unreadBadge}</div>`;
    }).join('');
    l.querySelectorAll('.conversation-item').forEach(el => el.addEventListener('click', () => openThread(el.dataset.cid, el.dataset.name)));
}

function openThread(targetCid, targetName) {
    TT = targetCid;
    $('thread-name').textContent = targetName;
    const conv = CV.find(c => c.cid === targetCid);
    const c = $('thread-messages');
    const myCid = PD.data ? PD.data.playerCid||'' : '';
    if (conv) {
        c.innerHTML = conv.messages.map(m => {
            const mine = m.sender_cid === myCid;
            return `<div class="msg-bubble ${mine?'msg-sent':'msg-received'}">${escHtml(m.content)}<div class="msg-time">${m.created_at||''}</div></div>`;
        }).join('');
        c.scrollTop = c.scrollHeight;
        const unreadIds = conv.messages.filter(m => m.receiver_cid === myCid && !m.read).map(m => m.id);
        if (unreadIds.length) fetch('https://'+GetRN()+'/close',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({ids:unreadIds})});
    } else c.innerHTML = '';
    $('conversations-list').classList.add('hidden');
    $('message-thread').classList.remove('hidden');
}

$('thread-back').onclick = () => { $('message-thread').classList.add('hidden'); $('conversations-list').classList.remove('hidden'); renderConversations(); };
$('msg-send').onclick = sendMsg;
$('msg-input').addEventListener('keydown', e => { if (e.key==='Enter') sendMsg(); });
function sendMsg() {
    const inp = $('msg-input');
    const content = inp.value.trim();
    if (!content||!TT) return;
    inp.value = '';
    fetch('https://'+GetRN()+'/sendMessage',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({targetCid:TT,content:content})});
    const c = $('thread-messages');
    c.innerHTML += `<div class="msg-bubble msg-sent">${escHtml(content)}<div class="msg-time">Just now</div></div>`;
    c.scrollTop = c.scrollHeight;
}
$('new-msg-btn').onclick = () => {
    dialog('New Message', [{id:'target',placeholder:'CID or Number'},{id:'msg',placeholder:'Message',type:'textarea'}], vals => {
        if (vals[0]&&vals[1]) fetch('https://'+GetRN()+'/sendMessage',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({targetCid:vals[0],content:vals[1]})});
    });
};

// ============ FACETIME ============
function renderFaceTime() {
    const l = $('facetime-list'); l.innerHTML = '';
    const myCid = PD.data?PD.data.playerCid||'':'';
    // Show recent FaceTime-like calls from contacts
    const ftCalls = PD.data?PD.data.callHistory||[]:[];
    const shown = new Set();
    ftCalls.forEach(c => {
        const other = c.caller_cid === myCid ? c.receiver_cid : c.caller_cid;
        if (shown.has(other)) return; shown.add(other);
        const d = document.createElement('div'); d.className = 'ft-item';
        d.innerHTML = `<div class="ft-avatar"><i class="fas fa-video"></i></div><div class="ft-info"><div class="ft-name">${other}</div><div class="ft-meta">${c.status}</div></div><button class="ft-btn" data-cid="${other}"><i class="fas fa-phone"></i></button>`;
        d.querySelector('.ft-btn').addEventListener('click', () => { /* FaceTime call - use same dial but with video flag */ });
        l.appendChild(d);
    });
}
$('facetime-new').onclick = () => {
    dialog('FaceTime', [{id:'target',placeholder:'CID or Number'}], vals => {
        if (vals[0]) fetch('https://'+GetRN()+'/dialNumber',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({number:vals[0]})});
    });
};

// ============ BANKING ============
$('transfer-btn').onclick = () => {
    const target = $('transfer-target').value.trim();
    const amount = $('transfer-amount').value.trim();
    if (!target||!amount) return;
    fetch('https://'+GetRN()+'/transferMoney',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({targetCid:target,number:target,amount:parseInt(amount)})});
};
function renderTxList() {
    const l = $('tx-list');
    const txs = PD.data?PD.data.transactions||[]:[];
    const myCid = PD.data?PD.data.playerCid||'':'';
    l.innerHTML = txs.map(t => {
        const isOut = t.sender_cid === myCid;
        return `<div class="tx-item"><span>${isOut?'To: '+t.receiver_cid:'From: '+t.sender_cid}</span><span class="${isOut?'tx-negative':'tx-positive'}">${isOut?'-':'+'}$${(t.amount||0).toLocaleString()}</span></div>`;
    }).join('');
}
PD.renderTxList = renderTxList;

// ============ CAMERA ============
function openCamera() {
    if (MS) { MS.getTracks().forEach(t => t.stop()); }
    navigator.mediaDevices.getUserMedia({video:{facingMode:'environment',width:{ideal:1280},height:{ideal:720}}}).then(s => { MS = s; $('camera-feed').srcObject = s; }).catch(() => { $('camera-feed').style.display = 'none'; });
}
$('camera-capture').onclick = () => {
    const v = $('camera-feed'); const cv = $('camera-canvas');
    cv.width = v.videoWidth||640; cv.height = v.videoHeight||480;
    cv.getContext('2d').drawImage(v,0,0,cv.width,cv.height);
    const data = cv.toDataURL('image/png');
    fetch('https://'+GetRN()+'/savePhoto',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({imageData:data})});
};
$('camera-flip').onclick = () => {
    if (MS) MS.getTracks().forEach(t => t.stop());
    navigator.mediaDevices.getUserMedia({video:{facingMode:'user',width:{ideal:1280},height:{ideal:720}}}).then(s => { MS = s; $('camera-feed').srcObject = s; }).catch(()=>{});
};

// ============ WEATHER ============
// Weather is loaded via NUI event 'loadWeather'

// ============ MAPS ============
$('maps-locate').onclick = () => {
    fetch('https://'+GetRN()+'/getCurrentLocation',{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'}).then(r=>r.json()).then(p=>{$('maps-coords').textContent=`📍 ${(p.lat||0).toFixed(4)}, ${(p.lon||0).toFixed(4)}`;});
};

// ============ MUSIC ============
const radioStations = [
    {name:'Los Santos Rock Radio',genre:'Rock'},
    {name:'Non-Stop Pop FM',genre:'Pop'},
    {name:'West Coast Classics',genre:'Hip Hop'},
    {name:'Radio Mirror Park',genre:'Indie'},
    {name:'Soulwax FM',genre:'Electronic'},
    {name:'FlyLo FM',genre:'Experimental'},
];
function renderMusic() {
    const l = $('music-stations');
    l.innerHTML = radioStations.map(s => `<div class="music-station"><span>${s.name}</span><span>${s.genre}</span></div>`).join('');
    l.querySelectorAll('.music-station').forEach(el => el.addEventListener('click', () => {
        $('music-title').textContent = el.querySelector('span').textContent;
        $('music-artist').textContent = 'Now Playing';
        $('music-play').querySelector('i').className = 'fas fa-pause';
    }));
}
$('music-play').onclick = function() {
    const icon = this.querySelector('i');
    icon.className = icon.className.includes('play') ? 'fas fa-pause' : 'fas fa-play';
};
renderMusic();

// ============ SOCIAL / TWEETS ============
function renderTweets(tweets) {
    const l = $('tweet-feed'); l.innerHTML = '';
    if (!tweets||!tweets.length) { l.innerHTML='<div style="padding:40px;text-align:center;color:#8e8e93">No tweets yet</div>'; return; }
    tweets.forEach(t => {
        const d = document.createElement('div'); d.className = 'tweet-item';
        const name = (t.firstname||'')+' '+(t.lastname||'').charAt(0)||'User';
        d.innerHTML = `<div class="tweet-header"><div class="tweet-avatar" style="background:#1DA1F2">${name[0]}</div><span class="tweet-author">${name}</span><span class="tweet-time">${t.created_at||''}</span></div><div class="tweet-content">${escHtml(t.content||'')}</div><div class="tweet-actions"><button class="tweet-like" data-id="${t.id}"><i class="fas fa-heart"></i> ${t.like_count||0}</button><button class="tweet-comment" data-id="${t.id}"><i class="fas fa-comment"></i> ${t.comment_count||0}</button><button class="tweet-rt" data-id="${t.id}"><i class="fas fa-retweet"></i></button></div>`;
        d.querySelector('.tweet-like').addEventListener('click', function() {
            fetch('https://'+GetRN()+'/likeTweet',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({tweetId:parseInt(this.dataset.id)})});
            this.classList.toggle('liked');
        });
        d.querySelector('.tweet-comment').addEventListener('click', function() {
            dialog('Reply', [{id:'comment',placeholder:'Write a reply...',type:'textarea'}], vals => {
                if (vals[0]) fetch('https://'+GetRN()+'/commentTweet',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({tweetId:parseInt(this.dataset.id),content:vals[0]})});
            });
        });
        d.querySelector('.tweet-rt').addEventListener('click', function() {
            fetch('https://'+GetRN()+'/retweet',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({tweetId:parseInt(this.dataset.id)})});
        });
        l.appendChild(d);
    });
}
$('tweet-btn').onclick = () => {
    dialog('New Tweet', [{id:'tweet',placeholder:'What is happening?',type:'textarea',rows:4}], vals => {
        if (vals[0]) fetch('https://'+GetRN()+'/postTweet',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({content:vals[0].substring(0,280)})});
    });
};

// ============ BLACK CHAT (Group Chats) ============
let bcCurrentRoom = null;
let bcMembers = [];

function renderBCRooms(rooms) {
    const l = $('bc-rooms'); l.innerHTML = '';
    if (!rooms||!rooms.length) { l.innerHTML='<div style="padding:20px;color:#8e8e93;text-align:center">No rooms. Create or join one!</div>'; return; }
    rooms.forEach(r => {
        const d = document.createElement('div'); d.className = 'bc-room-item';
        d.innerHTML = `<span>🔒 ${r.display_name||r.room_id}</span><span>${r.member_count||0} members</span>`;
        d.addEventListener('click', () => {
            fetch('https://'+GetRN()+'/joinBlackChatRoom',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({roomId:r.room_id})});
            bcCurrentRoom = r.room_id;
            $('bc-rooms').classList.add('hidden');
            $('bc-chat').classList.remove('hidden');
        });
        l.appendChild(d);
    });
}
$('bc-join-room').onclick = () => {
    dialog('Join/Create Room', [{id:'room',placeholder:'Room name'}], vals => {
        if (vals[0]) {
            fetch('https://'+GetRN()+'/joinBlackChatRoom',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({roomId:vals[0]})});
            bcCurrentRoom = vals[0];
            $('bc-rooms').classList.add('hidden');
            $('bc-chat').classList.remove('hidden');
        }
    });
};
$('bc-back').onclick = () => { $('bc-chat').classList.add('hidden'); $('bc-rooms').classList.remove('hidden'); bcCurrentRoom = null; };

$('bc-send').onclick = () => {
    const inp = $('bc-msg-input'); let content = inp.value.trim();
    if (!content) return; inp.value = '';
    const roomId = $('bc-room-name').textContent;
    if (!roomId) return;

    if (content.startsWith('/add ')) {
        const targetCid = content.substring(5).trim();
        if (targetCid) {
            fetch('https://'+GetRN()+'/addBlackChatMember',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({roomId:roomId,targetCid:targetCid})});
        }
        return;
    }

    const sd = parseInt($('bc-destruct').value)||0;
    fetch('https://'+GetRN()+'/sendBlackChatMessage',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({roomId:roomId,content:content,selfDestruct:sd})});
    addBCMessage({senderName:'You',content:content,created_at:'Just now',selfDestruct:sd});
};
$('bc-msg-input').addEventListener('keydown', e => { if (e.key==='Enter') $('bc-send').onclick(); });

$('bc-members-btn').onclick = () => {
    const panel = $('bc-members-panel');
    panel.classList.toggle('hidden');
    if (!panel.classList.contains('hidden')) {
        renderBCMembers();
    }
};

$('bc-add-member').onclick = () => {
    dialog('Add Member to ' + $('bc-room-name').textContent, [{id:'cid',placeholder:'Enter CID to add'}], vals => {
        if (vals[0]) {
            fetch('https://'+GetRN()+'/addBlackChatMember',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({roomId:$('bc-room-name').textContent,targetCid:vals[0]})});
        }
    });
};

function renderBCMembers() {
    const l = $('bc-members-list'); l.innerHTML = '';
    const myCid = PD.data ? PD.data.playerCid : '';
    bcMembers.forEach(m => {
        const name = (m.firstname||'')+' '+(m.lastname||'') || m.citizenid;
        const isMe = m.citizenid === myCid;
        const canRemove = !isMe && (m.role === 'owner' || bcMembers.find(x => x.citizenid === myCid && (x.role === 'owner' || x.role === 'admin')));
        const div = document.createElement('div'); div.className = 'bc-member-item';
        div.innerHTML = `<span class="member-name">${isMe?'👤 ':''}${name}</span><span class="member-role">${m.role}</span>${canRemove ? `<button class="member-remove" data-cid="${m.citizenid}"><i class="fas fa-times"></i></button>` : ''}`;
        const rmBtn = div.querySelector('.member-remove');
        if (rmBtn) rmBtn.addEventListener('click', () => {
            fetch('https://'+GetRN()+'/removeBlackChatMember',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({roomId:$('bc-room-name').textContent,targetCid:rmBtn.dataset.cid})});
            div.remove();
        });
        l.appendChild(div);
    });
}

function renderBCMessages(msgs) {
    const c = $('bc-messages'); c.innerHTML = '';
    msgs.forEach(m => addBCMessage(m));
}

function addBCMessage(m) {
    const c = $('bc-messages');
    const name = m.senderName||(m.firstname||'')+' '+(m.lastname||'')||m.sender||'User';
    const mine = name === 'You' || m.sender_cid === (PD.data?PD.data.playerCid:'');
    c.innerHTML += `<div class="msg-bubble ${mine?'msg-sent':'msg-received'}"><div style="font-size:10px;color:#ff4444;margin-bottom:2px">${mine?'You':name}</div>${escHtml(m.content)}<div class="msg-time">${m.created_at||''}${m.selfDestruct?' · Self-destruct':''}</div></div>`;
    c.scrollTop = c.scrollHeight;
}

// ============ BROWSER ============
document.querySelectorAll('.browser-tab').forEach(t => t.addEventListener('click', () => {
    document.querySelectorAll('.browser-tab').forEach(x => x.classList.remove('active'));
    t.classList.add('active'); switchBrowser(t.dataset.tab);
}));
function switchBrowser(tab) {
    const c = $('browser-content');
    const posts = {
        news: [
            {h:'City Council Approves New Budget',p:'Los Santos City Council approved a $50M infrastructure budget. Construction begins next month.'},
            {h:'Police Warn of Rising Vehicle Thefts',p:'LSPD reports 15% increase in vehicle thefts. Officers urge steering wheel locks.'},
            {h:'New Vinewood Restaurant Opening',p:'Upscale fusion restaurant opening on Vinewood Boulevard next week.'},
            {h:'Airport Expansion Underway',p:'LSIA terminal expansion will add 3 new gates by year end.'},
        ],
        social: [
            {h:'@driver_dan',p:'Just detailed my car at LS Customs! Looks fresh 🔥'},
            {h:'@pilot_sam',p:'Sunset over Mount Chiliad. Best view in the state.'},
            {h:'@mechanic_mike',p:'Open for business! Engine swaps, turbo installs, full service.'},
            {h:'@chef_maria',p:'New menu item: Truffle Wagyu Burger at Vespucci Bistro. Come try!'},
        ],
        weather: [
            {h:'Los Santos',p:'☀️ Sunny, 78°F (26°C)\nHumidity: 45%\nWind: 8 mph SW'},
            {h:'Blaine County',p:'⛅ Partly Cloudy, 72°F (22°C)\nHumidity: 52%\nWind: 12 mph W'},
            {h:'5-Day Forecast',p:'Mon: ☀️ 80° | Tue: 🌤️ 76° | Wed: 🌧️ 68° | Thu: ☀️ 74° | Fri: ☀️ 78°'},
        ]
    };
    const items = posts[tab]||[];
    c.innerHTML = items.map(i => `<div class="browser-post"><h4>${i.h}</h4><p>${i.p.replace(/\n/g,'<br>')}</p></div>`).join('');
}

// ============ NOTES ============
let notesData = [];
function renderNotes(notes) {
    notesData = notes||[];
    const l = $('notes-list'); l.innerHTML = '';
    if (!notesData.length) { l.innerHTML='<div style="padding:40px;text-align:center;color:#8e8e93">No notes</div>'; return; }
    notesData.forEach(n => {
        const d = document.createElement('div'); d.className = 'note-item';
        d.style.background = (n.color||'#FFD60A')+'22';
        d.style.borderLeft = '3px solid '+(n.color||'#FFD60A');
        d.innerHTML = `<div class="note-title">${n.title||'Untitled'}</div><div class="note-preview">${(n.content||'').substring(0,80)}</div><div class="note-date">${n.updated_at||n.created_at||''}</div>`;
        d.addEventListener('click', () => openNoteEditor(n));
        l.appendChild(d);
    });
}
function openNoteEditor(note) {
    $('notes-list').classList.add('hidden'); $('notes-editor').classList.remove('hidden');
    $('notes-title').value = note.title||'';
    $('notes-content').value = note.content||'';
    $('notes-editor').dataset.editId = note.id||'';
}
$('notes-add').onclick = () => openNoteEditor({title:'',content:'',color:'#FFD60A',id:''});
$('notes-editor-back').onclick = () => { $('notes-editor').classList.add('hidden'); $('notes-list').classList.remove('hidden'); fetch('https://'+GetRN()+'/getNotes',{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'}); };
$('notes-editor-done').onclick = () => {
    const id = $('notes-editor').dataset.editId;
    const title = $('notes-title').value.trim()||'Untitled';
    const content = $('notes-content').value;
    fetch('https://'+GetRN()+'/saveNote',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({id:id||null,title:title,content:content,color:'#FFD60A'})});
    $('notes-editor-back').onclick();
};

// ============ CALENDAR ============
function renderCalendar() {
    const y = calViewDate.getFullYear(), m = calViewDate.getMonth();
    $('cal-month').textContent = calViewDate.toLocaleDateString('en-US',{month:'long',year:'numeric'});
    const grid = $('cal-grid');
    let html = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'].map(d => `<div class="cal-day-header">${d}</div>`).join('');
    const first = new Date(y,m,1).getDay();
    const daysInMonth = new Date(y,m+1,0).getDate();
    const today = new Date();
    for (let i=0;i<first;i++) html += '<div></div>';
    for (let d=1;d<=daysInMonth;d++) {
        const isToday = d===today.getDate()&&m===today.getMonth()&&y===today.getFullYear();
        const hasEvent = calEvents.some(e => {
            const ed = new Date(e.date+'T'+ (e.time||'12:00'));
            return ed.getDate()===d && ed.getMonth()===m && ed.getFullYear()===y;
        });
        html += `<div class="cal-day${isToday?' today':''}${hasEvent?' has-event':''}">${d}</div>`;
    }
    grid.innerHTML = html;
    renderCalEvents();
}
function renderCalEvents() {
    const l = $('cal-events'); const d = calViewDate;
    const dayEvents = calEvents.filter(e => {
        const ed = new Date(e.date+'T'+(e.time||'12:00'));
        return ed.getDate()===d.getDate() && ed.getMonth()===d.getMonth() && ed.getFullYear()===d.getFullYear();
    });
    l.innerHTML = '<h3>Events</h3>';
    if (!dayEvents.length) { l.innerHTML += '<div style="color:#8e8e93;font-size:13px">No events today</div>'; return; }
    dayEvents.forEach(e => {
        const div = document.createElement('div'); div.className = 'cal-event-item';
        div.innerHTML = `<span class="evt-title">${e.title||'Event'}</span><span class="evt-time">${e.time||'12:00'}</span>`;
        l.appendChild(div);
    });
}
$('cal-prev').onclick = () => { calViewDate.setMonth(calViewDate.getMonth()-1); renderCalendar(); };
$('cal-next').onclick = () => { calViewDate.setMonth(calViewDate.getMonth()+1); renderCalendar(); };
$('calendar-add').onclick = () => {
    dialog('New Event', [{id:'title',placeholder:'Event title'},{id:'date',placeholder:'YYYY-MM-DD',value:new Date().toISOString().split('T')[0]},{id:'time',placeholder:'HH:MM (optional)',value:'12:00'}], vals => {
        if (vals[0]&&vals[1]) fetch('https://'+GetRN()+'/saveCalendarEvent',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({title:vals[0],date:vals[1],time:vals[2]||'12:00',description:''})});
    });
};

// ============ CLOCK ============
document.querySelectorAll('.clock-tab').forEach(t => t.addEventListener('click', () => switchClockTab(t.dataset.tab)));
function switchClockTab(tab) {
    document.querySelectorAll('.clock-tab').forEach(t => t.classList.remove('active'));
    document.querySelector(`.clock-tab[data-tab="${tab}"]`).classList.add('active');
    document.querySelectorAll('.clock-panel').forEach(p => p.classList.remove('active'));
    const p = $(`clock-${tab}`); if (p) p.classList.add('active');
}

// Timer
$('timer-start').onclick = function() {
    if (timerActive) { timerActive=false; this.textContent='Start'; this.classList.remove('active'); clearInterval(timerInterval); return; }
    timerActive=true; this.textContent='Pause'; this.classList.add('active');
    timerInterval = setInterval(() => {
        timerRemaining--;
        if (timerRemaining<=0) { clearInterval(timerInterval); timerActive=false; this.textContent='Start'; this.classList.remove('active'); timerRemaining=0; }
        const m=String(Math.floor(timerRemaining/60)).padStart(2,'0'), s=String(timerRemaining%60).padStart(2,'0');
        $('timer-display').textContent = m+':'+s;
    },1000);
};
$('timer-reset').onclick = () => { timerActive=false; clearInterval(timerInterval); timerRemaining=300; $('timer-display').textContent='05:00'; $('timer-start').textContent='Start'; $('timer-start').classList.remove('active'); };

// Stopwatch
$('sw-start').onclick = function() {
    if (swActive) { swActive=false; this.textContent='Start'; clearInterval(swInterval); return; }
    swActive=true; this.textContent='Stop';
    swInterval = setInterval(() => { swTime+=10; updateSW(); },10);
};
function updateSW() {
    const ms = swTime%1000, s = Math.floor(swTime/1000)%60, m = Math.floor(swTime/60000);
    $('stopwatch-display').textContent = String(m).padStart(2,'0')+':'+String(s).padStart(2,'0')+'.'+String(Math.floor(ms/10)).padStart(2,'0');
}
$('sw-lap').onclick = () => {
    if (!swActive) return;
    swLaps.push(swTime);
    const l = $('sw-laps');
    l.innerHTML = swLaps.map((t,i) => {
        const ms = t%1000, s = Math.floor(t/1000)%60, m = Math.floor(t/60000);
        return `<div class="sw-lap-item"><span>Lap ${i+1}</span><span>${String(m).padStart(2,'0')}:${String(s).padStart(2,'0')}.${String(Math.floor(ms/10)).padStart(2,'0')}</span></div>`;
    }).join('') + l.innerHTML;
};
$('sw-reset').onclick = () => { swActive=false; clearInterval(swInterval); swTime=0; swLaps=[]; updateSW(); $('sw-start').textContent='Start'; $('sw-laps').innerHTML=''; };

// ============ CALCULATOR ============
document.querySelectorAll('.calc-btn').forEach(b => b.addEventListener('click', () => calcPress(b.dataset.v)));
function calcPress(v) {
    const display = $('calc-display');
    if (v === 'AC') { calcStr=''; calcOp=null; calcPrev=null; calcClear=false; display.textContent='0'; return; }
    if (v === '±') { display.textContent = display.textContent.startsWith('-') ? display.textContent.slice(1) : '-'+display.textContent; return; }
    if (v === '%') { display.textContent = parseFloat(display.textContent)/100; return; }
    if (v === '=') {
        if (calcOp&&calcPrev!==null) {
            const curr = parseFloat(display.textContent);
            const results = {'+':calcPrev+curr,'-':calcPrev-curr,'*':calcPrev*curr,'/':curr!==0?calcPrev/curr:'Error'};
            display.textContent = results[calcOp]||'Error'; calcOp=null; calcPrev=null; calcClear=true;
        }
        return;
    }
    if ('+-*/'.includes(v)) { calcPrev = parseFloat(display.textContent); calcOp = v; calcClear = true; return; }
    if (calcClear) { display.textContent = v; calcClear = false; }
    else { display.textContent = display.textContent === '0' && v !== '.' ? v : display.textContent + v; }
}

// ============ WALLET ============
// Wallet uses bank data from banking. Also show any "passes" or tickets.
$('wallet-items').innerHTML = '<div style="color:#8e8e93;font-size:13px">No passes or tickets yet</div>';

// ============ APP STORE ============
const storeApps = [
    {name:'CityMapper',desc:'Navigation & Transit',icon:'fa-map',color:'#34C759'},
    {name:'SkyTracker',desc:'Flight Tracking',icon:'fa-plane',color:'#007AFF'},
    {name:'RP Portfolio',desc:'Character Manager',icon:'fa-user',color:'#5856D6'},
    {name:'Garage Remote',desc:'Vehicle Control',icon:'fa-car',color:'#FF2D55'},
    {name:'LS Weather Pro',desc:'Hyperlocal Weather',icon:'fa-cloud-sun',color:'#00BCD4'},
    {name:'Crypto Trade',desc:'Digital Currency',icon:'fa-bitcoin',color:'#FF9500'},
];
function renderAppStore() {
    const l = $('appstore-apps');
    l.innerHTML = storeApps.map(a => `<div class="appstore-app"><i class="fas ${a.icon}" style="background:${a.color}22;color:${a.color}"></i><div class="app-info"><div class="app-name">${a.name}</div><div class="app-desc">${a.desc}</div></div><button class="app-get">Get</button></div>`).join('');
}
renderAppStore();

// ============ SETTINGS ============
$('setting-silent').addEventListener('change', function() {
    fetch('https://'+GetRN()+'/setSilentMode',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({enabled:this.checked})});
});
$('setting-speaker').addEventListener('change', function() {
    fetch('https://'+GetRN()+'/setSpeaker',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({enabled:this.checked})});
});
document.querySelectorAll('.wallpaper-options button').forEach(b => b.addEventListener('click', function() {
    document.querySelectorAll('.wallpaper-options button').forEach(x => x.classList.remove('active'));
    this.classList.add('active');
    const wp = this.dataset.wp;
    const colors = {dark:'linear-gradient(135deg,#1a1a2e,#16213e)',blue:'linear-gradient(135deg,#007aff,#5856d6)',purple:'linear-gradient(135deg,#5856d6,#af52de)',green:'linear-gradient(135deg,#34c759,#30d158)'};
    $('phone').style.background = colors[wp]||colors.dark;
}));

// ============ BACK BUTTONS ============
document.querySelectorAll('.back-btn').forEach(btn => {
    btn.addEventListener('click', () => {
        if (MS) { MS.getTracks().forEach(t => t.stop()); MS = null; }
        showScreen('screen-home');
    });
});

// ============ TIME ============
function updateTime_() {
    const now = new Date();
    const h=now.getHours(), m=now.getMinutes();
    const timeStr = String(h).padStart(2,'0')+':'+String(m).padStart(2,'0');
    $('di-time').textContent = timeStr;
    $('status-time').textContent = timeStr;
}
setInterval(updateTime_, 10000); updateTime_();

// ============ UTILITY ============
function GetRN() { return window.location.hostname; }
function escHtml(s) { const d=document.createElement('div'); d.textContent=s; return d.innerHTML; }

// ============ KEYBOARD SHORTCUTS ============
document.addEventListener('keydown', e => {
    if (e.key === 'Escape') {
        if (!$('#incoming-call').classList.contains('hidden')) return; // don't close during call
        if (!$('#active-call').classList.contains('hidden')) return;
        if ($('dialog-overlay').classList.contains('active')) { $('dialog-overlay').classList.remove('active'); return; }
        if (CS !== 'screen-home') { showScreen('screen-home'); return; }
        fetch('https://'+GetRN()+'/closePhone',{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'});
    }
});

// Init banking tx list on load
setTimeout(() => { renderTxList(); }, 500);
PD.renderTxList = renderTxList;
