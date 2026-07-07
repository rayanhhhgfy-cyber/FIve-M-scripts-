// THEME: boot animation
const bootScreen = document.getElementById('bootScreen');
setTimeout(() => {
    bootScreen.classList.add('hidden');
    setTimeout(() => bootScreen.style.display = 'none', 600);
}, 2000);

// THEME: phone elements
const phone = document.getElementById('phone');
const screen = document.getElementById('screen');
const appHome = document.getElementById('appHome');
const appView = document.getElementById('appView');
const appGrid = document.getElementById('appGrid');
const dock = document.getElementById('dock');
const backBtn = document.getElementById('backBtn');
const appTitle = document.getElementById('appTitle');
const appContent = document.getElementById('appContent');
const timeDisplay = document.getElementById('timeDisplay');
const batteryDisplay = document.getElementById('batteryDisplay');
const wallpaper = document.getElementById('wallpaper');
const notifShade = document.getElementById('notifShade');

const voiceOverlay = document.getElementById('voiceOverlay');
const voiceMic = document.getElementById('voiceMic');
const voiceMode = document.getElementById('voiceMode');
const voiceTargets = document.getElementById('voiceTargets');
const voiceRadio = document.getElementById('voiceRadio');
const radioFreq = document.getElementById('radioFreq');
const voiceCallBadge = document.getElementById('voiceCallBadge');
const callPeerName = document.getElementById('callPeerName');
const callDuration = document.getElementById('callDuration');

const incomingCall = document.getElementById('incomingCall');
const incallAvatar = document.getElementById('incallAvatar');
const incallName = document.getElementById('incallName');
const acceptBtn = document.getElementById('acceptBtn');
const declineBtn = document.getElementById('declineBtn');

const activeCall = document.getElementById('activeCall');
const actcallAvatar = document.getElementById('actcallAvatar');
const actcallName = document.getElementById('actcallName');
const actcallDuration = document.getElementById('actcallDuration');
const endCallBtn = document.getElementById('endCallBtn');
const callMuteBtn = document.getElementById('callMuteBtn');
const callSpeakerBtn = document.getElementById('callSpeakerBtn');
const callKeypadBtn = document.getElementById('callKeypadBtn');

let contacts = [];
let messages = [];
let notes = [];
let photos = [];
let battery = 100;
let apps = {};
let dockApps = [];
let groups = [];
let blackChats = [];
let selectedGroup = null;

let callState = { active: false, peer: null, peerName: null, timer: null, seconds: 0, muted: false, speaker: false, incoming: null };
let voiceState = { mode: 'normal', talking: false, radioFreq: null, targets: [] };
let selectedConversation = null;
let dialerInput = ''; let xTweets=[]; let xProfile={}; let tiktokVideos=[]; let ubereatsRestaurants=[]; let ubereatsOrders=[]; let ueCart=[]; let bankBalance=0; let bankTransactions=[]; let myCitizenId=''; let calEvents=[]; let walletCards=[]; let videos=[]; let isRecording=false; let recordingFrames=[]; let recordingTimer=null;

const iconColors = {
    phone: '#27c93f', messages: '#27c93f', contacts: '#8b5cf6', camera: '#e92b2b',
    gallery: '#f0a500', settings: '#555', gps: '#0f3460', clock: '#000',
    notes: '#f0a500', contact_card: '#8b5cf6', locator: '#27c93f', vpn: '#8b5cf6',
    taxi: '#f0a500', blackchat: '#1a1a2e', music: '#FF2D55', calendar: '#FF3B30', calculator: '#333',
    wallet: '#2b7de9', appstore: '#2b7de9', browser: '#00d4ff', safari: '#00d4ff', vehicles: '#00d4ff',
    x: '#000000', tiktok: '#FF0050', ubereats: '#27c93f', banking: '#2b7de9', weather: '#5DADE2', gigs: '#f0a500', emergency: '#FF3B30',
};

const iconsSVG = {
    phone: '<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2" stroke-linecap="round"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"/></svg>',
    messages: '<svg width="26" height="26" viewBox="0 0 24 24" fill="#fff"><path d="M21 12a9 9 0 0 1-9 9H4l2.5-3.5A9 9 0 1 1 21 12z"/></svg>',
    contacts: '<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/></svg>',
    camera: '<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2"><path d="M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z"/><circle cx="12" cy="13" r="4"/></svg>',
    gallery: '<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2"><rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="8.5" cy="8.5" r="1.5"/><path d="M21 15l-5-5L5 21"/></svg>',
    settings: '<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>',
    gps: '<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/></svg>',
    clock: '<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2"><circle cx="12" cy="12" r="10"/><path d="M12 6v6l4 2"/></svg>',
    notes: '<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><path d="M14 2v6h6"/><path d="M12 18v-6"/><path d="M9 15h6"/></svg>',
    contact_card: '<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2"><rect x="2" y="4" width="20" height="16" rx="2"/><path d="M8 10a2 2 0 1 0 0-4 2 2 0 0 0 0 4z"/><path d="M4 16c0-2.5 2-4 4-4s4 1.5 4 4"/></svg>',
    locator: '<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2"><circle cx="12" cy="12" r="10"/><circle cx="12" cy="12" r="3"/><path d="M12 2v2M12 20v2M2 12h2M20 12h2"/></svg>',
    vpn: '<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2"><path d="M12 2S2 7 2 12c0 5 10 10 10 10s10-5 10-10c0-5-10-10-10-10z"/><circle cx="12" cy="12" r="4"/></svg>',
    taxi: '<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2"><path d="M5 17h14M7 7h10l3 5v5H4v-5l3-5z"/><circle cx="7" cy="17" r="2"/><circle cx="17" cy="17" r="2"/><path d="M10 7V4h4v3"/><rect x="4" y="12" width="16" height="1"/></svg>',
    blackchat: '<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/><path d="M8 10h.01M12 10h.01M16 10h.01" stroke-width="3" stroke-linecap="round"/></svg>',
    music: '<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2"><path d="M9 18V5l12-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="18" cy="16" r="3"/></svg>',
    calendar: '<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2"><rect x="3" y="4" width="18" height="18" rx="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>',
    calculator: '<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2"><rect x="4" y="2" width="16" height="20" rx="2"/><line x1="8" y1="6" x2="16" y2="6"/><line x1="8" y1="10" x2="8" y2="10.01"/><line x1="12" y1="10" x2="12" y2="10.01"/><line x1="16" y1="10" x2="16" y2="10.01"/><line x1="8" y1="14" x2="8" y2="14.01"/><line x1="12" y1="14" x2="12" y2="14.01"/><line x1="16" y1="14" x2="16" y2="14.01"/><line x1="8" y1="18" x2="16" y2="18"/></svg>',
    wallet: '<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2"><rect x="2" y="4" width="20" height="16" rx="2"/><path d="M16 12h4v4h-4"/><circle cx="18" cy="14" r="1"/></svg>',
    appstore: '<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2"><path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"/></svg>',
    browser: '<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/></svg>',
    safari: '<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2"><circle cx="12" cy="12" r="10"/><line x1="2" y1="12" x2="22" y2="12"/><path d="M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z"/></svg>',
    x: '<svg width="26" height="26" viewBox="0 0 24 24" fill="#fff"><path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"/></svg>',
    tiktok: '<svg width="26" height="26" viewBox="0 0 24 24" fill="#fff"><path d="M12.525.02c1.31-.02 2.61-.01 3.91-.02.08 1.53.63 3.09 1.75 4.17 1.12 1.11 2.7 1.62 4.24 1.79v4.03c-1.44-.05-2.89-.35-4.2-.97-.57-.26-1.1-.59-1.62-.93-.01 2.92.01 5.84-.02 8.75-.08 1.4-.54 2.79-1.35 3.94-1.31 1.92-3.58 3.17-5.91 3.21-1.43.08-2.86-.31-4.08-1.03-2.02-1.19-3.44-3.37-3.65-5.71-.02-.5-.03-1-.01-1.49.18-1.9 1.12-3.72 2.58-4.96 1.66-1.44 3.98-2.13 6.15-1.72.02 1.48-.04 2.96-.04 4.44-.99-.32-2.15-.23-3.02.37-.63.41-1.11 1.04-1.36 1.75-.21.51-.15 1.07-.14 1.61.24 1.64 1.82 3.02 3.5 2.87 1.12-.01 2.19-.66 2.77-1.61.19-.33.4-.67.41-1.06.1-1.79.06-3.57.07-5.36.01-4.03-.01-8.05.02-12.07z"/></svg>',
    ubereats: '<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2"><path d="M3 2v7c0 1.1.9 2 2 2h4a2 2 0 0 0 2-2V2"/><path d="M7 2v20"/><path d="M21 15V2v0a5 5 0 0 0-5 5v6c0 1.1.9 2 2 2h3Zm0 0v7"/></svg>',
    banking: '<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2"><path d="M2 10l10-7 10 7"/><rect x="4" y="10" width="16" height="11" rx="1"/><line x1="8" y1="14" x2="8" y2="18"/><line x1="16" y1="14" x2="16" y2="18"/><line x1="12" y1="14" x2="12" y2="18"/></svg>',
    weather: '<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2"><path d="M18 10h-1.26A8 8 0 1 0 9 20h9a5 5 0 0 0 0-10z"/><line x1="12" y1="1" x2="12" y2="3"/><line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/><line x1="1" y1="12" x2="3" y2="12"/><line x1="21" y1="12" x2="23" y2="12"/><line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/></svg>',
    gigs: '<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2"><rect x="2" y="7" width="20" height="14" rx="2"/><path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"/></svg>',
    emergency: '<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="10" y1="11" x2="14" y2="11"/></svg>',
    vehicles: '<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="2"><path d="M5 17h14M7 7h10l3 5v5H4v-5l3-5z"/><circle cx="7" cy="17" r="2"/><circle cx="17" cy="17" r="2"/><rect x="4" y="12" width="16" height="1"/></svg>',
};

function updateTime() { const n=new Date(); timeDisplay.textContent=n.getHours().toString().padStart(2,'0')+':'+n.getMinutes().toString().padStart(2,'0'); }
setInterval(updateTime,10000); updateTime();

function updateBattery(pct){
    batteryDisplay.textContent=pct+'%';
    battery=pct;
    const fill=document.getElementById('batteryFill');
    if(fill){fill.style.width=Math.min(pct,100)+'%';fill.style.fill=pct>20?'var(--accent-green)':'var(--accent-red)';}
}

// THEME: wallpaper support
function setWallpaper(gradient) {
    if (gradient) wallpaper.style.background = gradient;
    else wallpaper.style.background = 'linear-gradient(180deg, #0d0d2b 0%, #1a1a3e 40%, #0f0f23 100%)';
}

// THEME: notification shade
function toggleNotifShade() {
    notifShade.classList.toggle('open');
}
function closeNotifShade() {
    notifShade.classList.remove('open');
}

window.addEventListener('message',function(event){
    const d=event.data;
    if(d.action==='open'){
        phone.style.display='block';
        if(d.config){apps=d.config.Apps||{};dockApps=['phone','messages','gps','camera'];renderHome();}
        if(d.contacts){contacts=d.contacts;}
        if(d.messages){messages=d.messages;}
        if(d.notes){notes=d.notes;}
        battery=d.battery||100; updateBattery(battery);
    }
    if(d.action==='close'){phone.style.display='none';showHome();cleanupCall();}
    if(d.action==='loadData'){
        contacts=d.contacts||[];messages=d.messages||[];notes=d.notes||[];photos=d.photos||[];videos=d.videos||[];
        if(d.groups)groups=d.groups;
        battery=d.battery||100;updateBattery(battery);
        if(d.citizenid)myCitizenId=d.citizenid;
    }
    if(d.action==='newMessage'){const m=d.message;if(m){messages.push(m);if(selectedConversation)renderMessagesApp();}}
    if(d.action==='incomingCall'){showIncomingCall(d.caller,d.callerName);}
    if(d.action==='callConnected'){startActiveCall(d.peer,d.peerName);}
    if(d.action==='callEnded'){hideIncomingCall();hideActiveCall();}
    if(d.action==='taxiDispatch'){showTaxiApp();showTaxiDispatch(d);}
    if(d.action==='taxiFareUpdate'){if(taxiState.activeRide){taxiState.activeRide.fare=d.fare;taxiState.activeRide.distance=d.distance;renderTaxiApp();}}
    if(d.action==='voiceUpdate'){
        if(d.talking!==undefined){voiceState.talking=d.talking;voiceMic.classList.toggle('talking',d.talking);}
        if(d.mode){voiceState.mode=d.mode;voiceMode.textContent=d.mode;voiceMode.className='voice-mode '+d.mode.toLowerCase();}
        if(d.radioFreq!==undefined){
            voiceState.radioFreq=d.radioFreq;
            voiceRadio.style.display=d.radioFreq?'flex':'none';
            if(d.radioFreq)radioFreq.textContent=d.radioFreq.toFixed(1);
        }
        if(d.targets){voiceState.targets=d.targets;renderVoiceTargets();}
        voiceOverlay.style.display = (voiceState.talking||voiceState.radioFreq||callState.active||d.forceShow)?'flex':'none';
    }
    if(d.action==='callTimer'){actcallDuration.textContent=formatTime(d.elapsed);}
    if(d.action==='photoTaken'){if(d.data)photos.push(d.data);}
    if(d.action==='contactAdded'){contacts.push(d.contact);renderContactsApp();}
    if(d.action==='xData'){xTweets=d.tweets||[];if(appTitle.textContent==='X'&&!appView.classList.contains('hidden'))renderXApp();}
    if(d.action==='xNewTweet'){xTweets.unshift(d.tweet);if(appTitle.textContent==='X'&&!appView.classList.contains('hidden'))renderXApp();}
    if(d.action==='tiktokData'){tiktokVideos=d.videos||[];if(appTitle.textContent==='TikTok'&&!appView.classList.contains('hidden'))renderTikTokApp();}
    if(d.action==='ubereatsData'){ubereatsRestaurants=d.restaurants||[];if(appTitle.textContent==='Uber Eats'&&!appView.classList.contains('hidden'))renderUERestaurants();}
    if(d.action==='ubereatsOrders'){ubereatsOrders=d.orders||[];if(appTitle.textContent==='Uber Eats'&&!appView.classList.contains('hidden'))renderUEOrders();}
    if(d.action==='ubereatsOrderPlaced'){ubereatsOrders.unshift(d.order);Wrappers.Notify('Order placed! $'+(d.order.total||0).toFixed(2),'success');}
    if(d.action==='bankingData'){bankBalance=d.balance||0;bankTransactions=d.transactions||[];if(appTitle.textContent==='Banking'&&!appView.classList.contains('hidden')){const be=document.querySelector('.bank-balance-amount');if(be)be.textContent='$'+(bankBalance||0).toLocaleString();renderBankTransactions();}}
    if(d.action==='weatherData'){if(appTitle.textContent==='Weather'&&!appView.classList.contains('hidden')){renderWeatherApp();}}
    if(d.action==='gigsData'){gigs=d.gigs||[];if(appTitle.textContent==='Gigs'&&!appView.classList.contains('hidden'))renderGigsApp();}
    if(d.action==='gigCreated'){gigs.unshift(d.gig);Wrappers.Notify('Gig posted!','success');if(appTitle.textContent==='Gigs'&&!appView.classList.contains('hidden'))renderGigsApp();}
    if(d.action==='calendarData'){calEvents=d.events||[];if(appTitle.textContent==='Calendar'&&!appView.classList.contains('hidden'))renderCalendarApp();}
    if(d.action==='walletData'){walletCards=d.cards||[];if(appTitle.textContent==='Wallet'&&!appView.classList.contains('hidden'))renderWalletApp();}
    if(d.action==='videoSaved'){if(d.data){videos.push(d.data);}}
    // THEME: wallpaper update via event
    if(d.action==='setWallpaper'){setWallpaper(d.gradient);}
});

function renderVoiceTargets(){
    voiceTargets.innerHTML='';
    for(let i=0;i<Math.max(voiceState.targets.length||0,4);i++){
        const dot=document.createElement('div');
        dot.className='voice-target-dot'+(i<(voiceState.targets.length||0)?' active':'');
        voiceTargets.appendChild(dot);
    }
}

// THEME: staggered entrance for app icons
function renderHome(){
    appGrid.innerHTML='';dock.innerHTML='';
    const dockSet=new Set(dockApps);
    let idx = 0;
    Object.entries(apps).forEach(([key,app])=>{
        if(!dockSet.has(key)){
            const icon = createAppIcon(key,app);
            icon.style.animationDelay = (idx * 0.04) + 's';
            appGrid.appendChild(icon);
            idx++;
        }
    });
    dockApps.forEach(key=>{
        if(apps[key]){
            const icon = createAppIcon(key,apps[key]);
            icon.style.animationDelay = (idx * 0.04) + 's';
            dock.appendChild(icon);
            idx++;
        }
    });
    closeNotifShade();
}

function createAppIcon(key,app){
    const div=document.createElement('div');div.className='app-icon';
    const color=iconColors[key]||'#555';
    div.innerHTML=`<div class="icon-wrap" style="background:${color}">${iconsSVG[key]||''}</div><span class="label">${app.label}</span>`;
    // THEME: icon bounce on tap
    div.addEventListener('click',()=>{
        div.style.animation='none';
        div.offsetHeight;
        div.style.animation='scalePulse 0.3s ease';
        setTimeout(()=>openApp(key),150);
    });
    return div;
}

backBtn.addEventListener('click',showHome);

function showHome(){
    appView.classList.add('hidden');appHome.classList.remove('hidden');incomingCall.classList.add('hidden');
    activeCall.classList.add('hidden');
    closeNotifShade();
    fetch(`https://${GetParentResourceName()}/close`,{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'});
}

function openApp(key){
    appHome.classList.add('hidden');appView.classList.remove('hidden');
    appContent.innerHTML='';const app=apps[key];
    appTitle.textContent=app?app.label:'App';
    switch(key){
        case 'phone':renderPhoneApp();break;
        case 'messages':renderMessagesApp();break;
        case 'contacts':renderContactsApp();break;
        case 'camera':renderCameraApp();break;
        case 'gallery':renderGalleryApp();break;
        case 'settings':renderSettingsApp();break;
        case 'gps':renderGpsApp();break;
        case 'clock':renderClockApp();break;
        case 'notes':renderNotesApp();break;
        case 'contact_card':renderContactCardApp();break;
        case 'locator':renderLocatorApp();break;
        case 'vpn':renderVpnApp();break;
        case 'taxi':renderTaxiApp();break;
        case 'blackchat':renderBlackChatApp();break;
        case 'music':renderMusicApp();break;
        case 'calendar':renderCalendarApp();break;
        case 'calculator':renderCalculatorApp();break;
        case 'wallet':renderWalletApp();break;
        case 'appstore':renderAppStoreApp();break;
        case 'browser':case 'safari':renderBrowserApp();break;
        case 'x':renderXApp();break;
        case 'tiktok':renderTikTokApp();break;
        case 'ubereats':renderUberEatsApp();break;
        case 'banking':renderBankingApp();break;
        case 'weather':renderWeatherApp();break;
        case 'gigs':renderGigsApp();break;
        case 'emergency':renderEmergencyApp();break;
        case 'vehicles':renderVehiclesApp();break;
        default:appContent.innerHTML='<div class="placeholder-app">Coming soon</div>';
    }
    closeNotifShade();
}

/* ==================== PHONE APP (DIALER) ==================== */
let dialerTab='keypad';
function renderPhoneApp(){
    appTitle.textContent='Phone';
    let html=`
        <div class="dialer-tabs">
            <div class="dialer-tab ${dialerTab==='keypad'?'active':''}" onclick="switchDialerTab('keypad')">Keypad</div>
            <div class="dialer-tab ${dialerTab==='recents'?'active':''}" onclick="switchDialerTab('recents')">Recents</div>
            <div class="dialer-tab ${dialerTab==='contacts'?'active':''}" onclick="switchDialerTab('contacts')">Contacts</div>
        </div>
        <div id="dialerContent"></div>
    `;
    appContent.innerHTML=html;
    renderDialerTab();
}

function switchDialerTab(tab){dialerTab=tab;renderPhoneApp();}

function renderDialerTab(){
    const el=document.getElementById('dialerContent');if(!el)return;
    if(dialerTab==='keypad')renderKeypad();
    else if(dialerTab==='recents')renderRecents();
    else renderDialerContacts();
}

function renderKeypad(){
    const el=document.getElementById('dialerContent');
    const keys=[
        ['1',''],['2','ABC'],['3','DEF'],
        ['4','GHI'],['5','JKL'],['6','MNO'],
        ['7','PQRS'],['8','TUV'],['9','WXYZ'],
        ['*',''],['0','+'],['#',''],
    ];
    let html=`<div class="dialer-display" id="dialerDisplay">${dialerInput||''}</div>
    <div class="dialer-grid">`;
    keys.forEach(([n,s])=>{
        html+=`<button class="dialer-key" onclick="dialerPress('${n}')">${n}${s?`<span class="sub">${s}</span>`:''}</button>`;
    });
    html+=`<button class="dialer-key delete-key" onclick="dialerDelete()">⌫</button>
    <button class="dialer-key call-key" onclick="dialerCall()">📞</button>
    </div>`;
    el.innerHTML=html;
}

function dialerPress(n){dialerInput+=n;renderKeypad();}
function dialerDelete(){dialerInput=dialerInput.slice(0,-1);renderKeypad();}
function dialerCall(){
    if(!dialerInput.trim())return;
    const number=dialerInput.replace(/\s/g,'');
    fetch(`https://${GetParentResourceName()}/dialNumber`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({number})});
}

function renderRecents(){
    const el=document.getElementById('dialerContent');
    fetch(`https://${GetParentResourceName()}/getCallHistory`,{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'}).then(r=>r.json()).then(history=>{
        if(!history||history.length===0){el.innerHTML='<div style="text-align:center;padding:40px;color:rgba(255,255,255,0.2);font-size:13px">No recent calls</div>';return;}
        let html='';
        history.forEach(c=>{
            const iconClass=c.missed?'missed':(c.answered?'answered':'outgoing');
            html+=`<div class="recents-item">
                <span class="recents-icon ${iconClass}">${c.missed?'📞':(c.answered?'📞':'📞')}</span>
                <span class="recents-name">${c.name||c.number||'Unknown'}</span>
                <span class="recents-time">${c.time||''}</span>
            </div>`;
        });
        el.innerHTML=html;
    }).catch(()=>{
        el.innerHTML='<div style="text-align:center;padding:40px;color:rgba(255,255,255,0.2);font-size:13px">No recent calls</div>';
    });
}

function renderDialerContacts(){
    const el=document.getElementById('dialerContent');
    if(contacts.length===0){el.innerHTML='<div style="text-align:center;padding:40px;color:rgba(255,255,255,0.2);font-size:13px">No contacts</div>';return;}
    let html='';
    contacts.forEach(c=>{
        const initial=c.name?c.name.charAt(0).toUpperCase():'?';
        html+=`<div class="contact-item" onclick="dialContact('${c.number||''}')">
            <div class="contact-avatar">${initial}</div>
            <div class="contact-info"><div class="contact-name">${c.name||'Unknown'}</div><div class="contact-number">${c.number||''}</div></div>
        </div>`;
    });
    el.innerHTML=html;
}

function dialContact(number){if(number){dialerInput=number;dialerTab='keypad';renderPhoneApp();}}

/* ==================== MESSAGES APP ==================== */
function renderMessagesApp(){
    appTitle.textContent='Messages';
    if(selectedConversation){
        if(selectedConversation.startsWith('group_')){
            renderGroupConversation();return;
        }
        renderConversation();return;
    }
    const convs=getConversations();
    let html='<div style="display:flex;gap:8px;padding:4px 8px 8px">';
    html+=`<button class="add-contact-btn" style="flex:1;font-size:12px" onclick="showNewMessage()">✏️ New</button>`;
    html+=`<button class="add-contact-btn" style="flex:1;font-size:12px" onclick="showNewGroup()">👥 Group</button>`;
    html+='</div>';
    const hasGroups=groups.length>0;
    const hasConvs=convs.length>0;
    if(!hasGroups&&!hasConvs){
        html+='<div style="text-align:center;padding:60px 0;color:rgba(255,255,255,0.2);font-size:13px">No conversations</div>';
    }else{
        if(hasGroups){
            html+='<div style="color:rgba(255,255,255,0.3);font-size:11px;padding:0 16px 4px">GROUPS</div>';
            groups.forEach(g=>{
                const lastMsg=g.messages&&g.messages.length>0?g.messages[g.messages.length-1]:null;
                const initial=g.name?g.name.charAt(0).toUpperCase():'G';
                html+=`<div class="conversation-item" onclick="selectedConversation='group_${g.id}';renderMessagesApp()">
                    <div class="conversation-avatar" style="background:#5856D6">${initial}</div>
                    <div class="conversation-info">
                        <div class="conversation-name">${g.name||'Group'}</div>
                        <div class="conversation-preview">${lastMsg?lastMsg.content:'Group created'}</div>
                    </div>
                    <div style="text-align:right;font-size:10px;color:rgba(255,255,255,0.3)">${(g.members||[]).length}m</div>
                </div>`;
            });
        }
        if(hasConvs){
            html+='<div style="color:rgba(255,255,255,0.3);font-size:11px;padding:4px 16px">MESSAGES</div>';
            html+='<div class="contact-list">';
            convs.forEach(c=>{
                const initial=c.name?c.name.charAt(0).toUpperCase():'?';
                html+=`<div class="conversation-item" onclick="openConversation('${c.number}')">
                    <div class="conversation-avatar">${initial}</div>
                    <div class="conversation-info">
                        <div class="conversation-name">${c.name||c.number||'Unknown'}</div>
                        <div class="conversation-preview">${c.lastMsg||''}</div>
                    </div>
                    <div style="text-align:right">
                        <div class="conversation-time">${c.lastTime||''}</div>
                        ${(c.unread||0)>0?`<div class="conversation-unread">${c.unread}</div>`:''}
                    </div>
                </div>`;
            });
            html+='</div>';
        }
    }
    appContent.innerHTML=html;
}

function showNewGroup(){
    let html='<div style="padding:8px 0"><input class="msg-input" id="groupName" placeholder="Group name" style="margin-bottom:8px" /></div>';
    html+='<div style="color:rgba(255,255,255,0.3);font-size:11px;margin:8px 0">Add Contacts</div>';
    contacts.forEach(c=>{
        html+=`<label style="display:flex;align-items:center;gap:12px;padding:8px 0;cursor:pointer">
            <input type="checkbox" class="group-member-cb" value="${c.number||''}" />
            <div class="contact-avatar" style="width:28px;height:28px;font-size:12px">${c.name.charAt(0).toUpperCase()}</div>
            <span style="color:#fff;font-size:13px">${c.name}</span>
        </label>`;
    });
    html+=`<button class="taxi-accept-btn" onclick="createGroup()" style="margin-top:12px">Create Group</button>`;
    appContent.innerHTML=html;
}

function createGroup(){
    const name=document.getElementById('groupName')?.value||'Untitled';
    const cbs=document.querySelectorAll('.group-member-cb:checked');
    const members=[];cbs.forEach(cb=>{if(cb.value)members.push(cb.value);});
    if(members.length<1){Wrappers.Notify('Add at least 1 member','error');return;}
    const gid='g_'+Date.now();
    fetch(`https://${GetParentResourceName()}/createGroup`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({name,members})});
    groups.push({id:gid,name,members,messages:[]});
    selectedConversation='group_'+gid;
    renderMessagesApp();
}

function getConversations(){
    const groups={};
    messages.forEach(m=>{
        const key=m.sender||m.number||'unknown';
        if(!groups[key])groups[key]={number:key,name:m.senderName||m.sender||key,lastMsg:m.content||'',lastTime:m.time?formatMsgTime(m.time):'',unread:0,msgs:[]};
        groups[key].lastMsg=m.content||'';
        groups[key].lastTime=m.time?formatMsgTime(m.time):'';
        if(m.incoming)groups[key].unread=(groups[key].unread||0)+1;
        groups[key].msgs.push(m);
    });
    return Object.values(groups).sort((a,b)=>b.lastTime-a.lastTime);
}

function openConversation(number){
    selectedConversation=number;
    renderMessagesApp();
}

function renderConversation(){
    const convs=getConversations();
    const conv=convs.find(c=>c.number===selectedConversation);
    const name=conv?conv.name:selectedConversation;
    appTitle.textContent=name;
    const msgs=conv?conv.msgs:[];
    let html='<div class="msg-list" id="msgList">';
    msgs.forEach(m=>{
        const cls=m.incoming?'msg-incoming':'msg-outgoing';
        let body=m.content||'';
        if(m.image)body+=`<img src="${m.image}" class="msg-image" onclick="window.open('${m.image}','_blank')" />`;
        if(m.video)body+=`<video src="${m.video}" class="msg-video" controls></video>`;
        html+=`<div class="msg-bubble ${cls}">${body}<span class="msg-time">${m.time?formatMsgTime(m.time):''}</span></div>`;
    });
    html+=`</div><div class="msg-input-wrap">
        <input class="msg-input" id="msgInput" placeholder="iMessage" />
        <button class="msg-attach" id="msgAttach" title="Attach image">📷</button>
        <button class="msg-send" id="msgSend">Send</button>
    </div>`;
    appContent.innerHTML=html;
    appTitle.parentElement.querySelector('.back-btn').onclick=function(){selectedConversation=null;renderMessagesApp();};
    const list=document.getElementById('msgList');if(list)list.scrollTop=list.scrollHeight;
    document.getElementById('msgAttach').addEventListener('click',function(){
        const input=document.createElement('input');input.type='file';input.accept='image/*';
        input.onchange=function(e){
            const file=e.target.files[0];if(!file)return;
            const reader=new FileReader();
            reader.onload=function(ev){
                const dataUrl=ev.target.result;
                fetch(`https://${GetParentResourceName()}/sendImage`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({number:selectedConversation,image:dataUrl})});
                messages.push({sender:selectedConversation,image:dataUrl,incoming:false,time:Date.now()/1000});
                renderConversation();
            };
            reader.readAsDataURL(file);
        };
        input.click();
    });
    document.getElementById('msgSend').addEventListener('click',function(){
        const input=document.getElementById('msgInput');
        if(input.value.trim()){
            fetch(`https://${GetParentResourceName()}/sendMessage`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({number:selectedConversation,content:input.value})});
            messages.push({sender:selectedConversation,content:input.value,incoming:false,time:Date.now()/1000});
            input.value='';renderConversation();
        }
    });
}

function renderGroupConversation(){
    const gid=selectedConversation.replace('group_','');
    const group=groups.find(g=>g.id===gid);
    if(!group){appContent.innerHTML='<div>Group not found</div>';return;}
    appTitle.textContent=group.name||'Group';
    const msgs=group.messages||[];
    let html='<div class="msg-list" id="msgList">';
    msgs.forEach(m=>{
        const cls=m.incoming?'msg-incoming':'msg-outgoing';
        let body=m.content||'';
        if(m.image)body+=`<img src="${m.image}" class="msg-image" />`;
        if(m.video)body+=`<video src="${m.video}" class="msg-video" controls></video>`;
        html+=`<div class="msg-bubble ${cls}">${m.senderName?`<div style="font-size:10px;color:rgba(255,255,255,0.4);margin-bottom:2px">${m.senderName}</div>`:''}${body}<span class="msg-time">${m.time?formatMsgTime(m.time):''}</span></div>`;
    });
    html+=`</div><div class="msg-input-wrap">
        <input class="msg-input" id="groupMsgInput" placeholder="Group message..." />
        <button class="msg-attach" id="groupMsgAttach" title="Attach image">📷</button>
        <button class="msg-send" id="groupMsgSend">Send</button>
    </div>`;
    appContent.innerHTML=html;
    appTitle.parentElement.querySelector('.back-btn').onclick=function(){selectedConversation=null;renderMessagesApp();};
    const list=document.getElementById('msgList');if(list)list.scrollTop=list.scrollHeight;
    document.getElementById('groupMsgAttach').addEventListener('click',function(){
        const input=document.createElement('input');input.type='file';input.accept='image/*';
        input.onchange=function(e){
            const file=e.target.files[0];if(!file)return;
            const reader=new FileReader();
            reader.onload=function(ev){
                const dataUrl=ev.target.result;
                fetch(`https://${GetParentResourceName()}/sendGroupImage`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({groupId:gid,image:dataUrl})});
                group.messages.push({image:dataUrl,incoming:false,time:Date.now()/1000});
                renderGroupConversation();
            };
            reader.readAsDataURL(file);
        };
        input.click();
    });
    document.getElementById('groupMsgSend').addEventListener('click',function(){
        const input=document.getElementById('groupMsgInput');
        if(input.value.trim()){
            fetch(`https://${GetParentResourceName()}/sendGroupMessage`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({groupId:gid,content:input.value})});
            group.messages.push({content:input.value,incoming:false,time:Date.now()/1000});
            input.value='';renderGroupConversation();
        }
    });
}

function showNewMessage(){
    let html='<div style="padding:8px 0"><input class="msg-input" id="newMsgNumber" placeholder="Phone number" style="margin-bottom:8px" /></div>';
    if(contacts.length>0){
        html+='<div style="color:rgba(255,255,255,0.3);font-size:11px;margin:8px 0">Contacts</div>';
        contacts.forEach(c=>{
            html+=`<div class="contact-item" onclick="document.getElementById('newMsgNumber').value='${c.number||''}';">
                <div class="contact-avatar">${c.name.charAt(0).toUpperCase()}</div>
                <div class="contact-info"><div class="contact-name">${c.name}</div><div class="contact-number">${c.number}</div></div>
            </div>`;
        });
    }
    html+=`<button class="taxi-accept-btn" onclick="startNewConversation()" style="margin-top:8px">Start Chat</button>`;
    appContent.innerHTML=html;
}

function startNewConversation(){
    const num=document.getElementById('newMsgNumber')?.value;
    if(num){selectedConversation=num;renderMessagesApp();}
}

/* ==================== CONTACTS APP ==================== */
function renderContactsApp(){
    appTitle.textContent='Contacts';
    let html=`<button class="add-contact-btn" onclick="showAddContact()">➕ Add Contact</button><div class="contact-list">`;
    if(contacts.length===0){html+='<div style="text-align:center;padding:40px;color:rgba(255,255,255,0.2);font-size:13px">No contacts</div>';}
    contacts.forEach(c=>{
        const initial=c.name?c.name.charAt(0).toUpperCase():'?';
        html+=`<div class="contact-item" onclick="contactOptions('${c.id||c.name}','${c.name||''}','${c.number||''}')">
            <div class="contact-avatar">${initial}</div>
            <div class="contact-info"><div class="contact-name">${c.name||'Unknown'}</div><div class="contact-number">${c.number||''}</div></div>
        </div>`;
    });
    html+='</div>';
    appContent.innerHTML=html;
}

function showAddContact(){
    appContent.innerHTML=`
        <input class="msg-input" id="newContactName" placeholder="Name" style="margin-bottom:8px" />
        <input class="msg-input" id="newContactNumber" placeholder="Phone number" style="margin-bottom:12px" />
        <button class="taxi-accept-btn" onclick="saveNewContact()">Save Contact</button>
    `;
}

function saveNewContact(){
    const name=document.getElementById('newContactName')?.value;
    const number=document.getElementById('newContactNumber')?.value;
    if(name&&number){
        fetch(`https://${GetParentResourceName()}/addContact`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({name,number})});
        contacts.push({name,number});
        renderContactsApp();
    }
}

function contactOptions(id,name,number){
    Wrappers.ContextMenu({
        id:'contact_ops',title:name,
        menuItems:[
            {title:'Call',onSelect:function(){dialerInput=number;dialerTab='keypad';renderPhoneApp();}},
            {title:'Message',onSelect:function(){selectedConversation=number;renderMessagesApp();}},
        ]
    });
}

/* ==================== CAMERA APP (PHOTO + VIDEO) ==================== */
let cameraStream=null;
function renderCameraApp(){
    appTitle.textContent='Camera';
    let html=`
        <div class="camera-view" id="cameraPreview"><div style="color:rgba(255,255,255,0.2);font-size:14px;text-align:center;padding-top:80px">📷</div></div>
        <div class="camera-mode-bar">
            <button class="cam-mode-btn ${!isRecording?'active':''}" onclick="switchCamMode('photo')" id="camPhotoBtn">📷 Photo</button>
            <button class="cam-mode-btn ${isRecording?'active':''}" onclick="switchCamMode('video')" id="camVideoBtn">🎥 Video</button>
        </div>
        <div class="camera-btn-wrap" id="camBtnWrap">
            <div class="cam-timer" id="camTimer" style="display:${isRecording?'block':'none'}">00:00</div>
    `;
    if(isRecording){
        html+=`<button class="cam-record-btn stop" id="cameraCaptureBtn"><div class="cam-record-inner" style="background:#ff3b30;border-radius:4px;width:16px;height:16px"></div></button>`;
    }else{
        html+=`<button class="camera-btn" id="cameraCaptureBtn"><div class="camera-btn-inner"></div></button>`;
    }
    html+=`</div>`;
    appContent.innerHTML=html;
    document.getElementById('cameraCaptureBtn').addEventListener('click',function(){
        if(isRecording){stopVideoRecording();}
        else{takePhoto();}
    });
}

function switchCamMode(mode){
    if(mode==='video'&&!isRecording){isRecording=true;renderCameraApp();startVideoRecording();}
    else if(mode==='photo'&&isRecording){isRecording=false;if(recordingTimer){clearInterval(recordingTimer);recordingTimer=null;}recordingFrames=[];renderCameraApp();}
}

function takePhoto(){
    fetch(`https://${GetParentResourceName()}/takePhoto`,{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'});
    Wrappers.Notify('📸 Photo captured','success');
}

function startVideoRecording(){
    if(recordingTimer)return;
    recordingFrames=[];
    let sec=0;
    const timerEl=document.getElementById('camTimer');
    Wrappers.Notify('🔴 Recording... tap stop when done','info');
    recordingTimer=setInterval(function(){
        sec++;
        if(timerEl)timerEl.textContent=String(Math.floor(sec/60)).padStart(2,'0')+':'+String(sec%60).padStart(2,'0');
        if(sec>30){stopVideoRecording();Wrappers.Notify('⏱ Max 30s reached','error');return;}
        fetch(`https://${GetParentResourceName()}/captureFrame`,{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'})
            .then(r=>r.json()).then(d=>{if(d&&d.data)recordingFrames.push(d.data);});
    },200);
}

function stopVideoRecording(){
    if(recordingTimer){clearInterval(recordingTimer);recordingTimer=null;}
    isRecording=false;
    Wrappers.Notify('⏹ Saving '+(recordingFrames.length||0)+' frames...','info');
    const thumbnail=recordingFrames[0]||'';
    const videoData=JSON.stringify(recordingFrames);
    fetch(`https://${GetParentResourceName()}/saveVideo`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({videoData:videoData,thumbnail:thumbnail})});
    videos.push({video_data:videoData,thumbnail:thumbnail,created_at:Math.floor(Date.now()/1000)});
    recordingFrames=[];
    setTimeout(function(){renderCameraApp();Wrappers.Notify('✅ Video saved to gallery','success');},300);
}

/* ==================== GALLERY APP (PHOTOS + VIDEOS) ==================== */
let galleryTab='photos';
function renderGalleryApp(){
    appTitle.textContent='Gallery';
    let html=`<div class="gallery-tabs"><div class="gallery-tab ${galleryTab==='photos'?'active':''}" onclick="switchGalleryTab('photos')">📷 Photos</div><div class="gallery-tab ${galleryTab==='videos'?'active':''}" onclick="switchGalleryTab('videos')">🎥 Videos</div></div><div id="galleryContent"></div>`;
    appContent.innerHTML=html;
    if(galleryTab==='photos')renderPhotos();else renderVideos();
}
function switchGalleryTab(t){galleryTab=t;renderGalleryApp();}

function renderPhotos(){
    const el=document.getElementById('galleryContent');
    if(!photos||photos.length===0){el.innerHTML='<div style="text-align:center;padding:60px 0;color:rgba(255,255,255,0.2);font-size:13px">No photos yet</div>';return;}
    let html='<div class="photo-grid">';
    photos.forEach((p,i)=>{
        const src=p.image_data||p.data||p;
        html+=`<div class="photo-item" onclick="viewPhoto(${i})"><img src="${src}" /></div>`;
    });
    html+='</div>';el.innerHTML=html;
}

function renderVideos(){
    const el=document.getElementById('galleryContent');
    const allVids=[...videos];
    if(allVids.length===0){el.innerHTML='<div style="text-align:center;padding:60px 0;color:rgba(255,255,255,0.2);font-size:13px">No videos yet</div>';return;}
    let html='<div class="photo-grid">';
    allVids.forEach((v,i)=>{
        const thumb=v.thumbnail||'';
        html+=`<div class="photo-item video-item" onclick="playVideo(${i})">
            ${thumb?`<img src="${thumb}" />`:'<div class="video-thumb-placeholder">🎥</div>'}
            <div class="video-play-overlay">▶</div>
        </div>`;
    });
    html+='</div>';el.innerHTML=html;
}

function viewPhoto(idx){
    const p=photos[idx];if(!p)return;
    const src=p.image_data||p.data||p;
    appContent.innerHTML=`
        <div style="display:flex;flex-direction:column;align-items:center;gap:12px;padding:20px 0">
            <img src="${src}" style="max-width:100%;max-height:400px;border-radius:12px;box-shadow:0 4px 20px rgba(0,0,0,0.5)" />
            <button class="note-save" onclick="renderGalleryApp()">← Back</button>
        </div>
    `;
}

let videoPlaybackTimer=null;
function playVideo(idx){
    const allVids=[...videos];
    const v=allVids[idx];if(!v||!v.video_data)return;
    let frames;
    try{frames=JSON.parse(v.video_data);}catch(e){Wrappers.Notify('Error loading video','error');return;}
    if(!frames||frames.length===0){Wrappers.Notify('Empty video','error');return;}
    let frameIdx=0;
    appContent.innerHTML=`
        <div style="display:flex;flex-direction:column;align-items:center;gap:12px;padding:16px 0">
            <div class="video-player-wrap">
                <img id="vidFrame" src="${frames[0]}" style="width:100%;max-height:400px;border-radius:12px;box-shadow:0 4px 20px rgba(0,0,0,0.5)" />
                <div class="video-progress-bar"><div class="video-progress-fill" id="vidProgress" style="width:0%"></div></div>
            </div>
            <div style="display:flex;gap:8px">
                <button class="note-save" id="vidPlayBtn" onclick="toggleVideoPlay()">⏸ Pause</button>
                <button class="note-save" onclick="renderGalleryApp()">← Back</button>
            </div>
            <div style="color:rgba(255,255,255,0.3);font-size:11px" id="vidFrameCount">Frame 1/${frames.length}</div>
        </div>
    `;
    if(videoPlaybackTimer)clearInterval(videoPlaybackTimer);
    videoPlaybackTimer=setInterval(function(){
        frameIdx=(frameIdx+1)%frames.length;
        const img=document.getElementById('vidFrame');
        if(img){img.src=frames[frameIdx];}
        const prog=document.getElementById('vidProgress');
        if(prog){prog.style.width=((frameIdx+1)/frames.length*100)+'%';}
        const fc=document.getElementById('vidFrameCount');
        if(fc){fc.textContent='Frame '+(frameIdx+1)+'/'+frames.length;}
    },100);
    let playing=true;
    window.toggleVideoPlay=function(){
        playing=!playing;
        const btn=document.getElementById('vidPlayBtn');
        if(playing){
            btn.textContent='⏸ Pause';
            videoPlaybackTimer=setInterval(function(){
                frameIdx=(frameIdx+1)%frames.length;
                const img=document.getElementById('vidFrame');
                if(img)img.src=frames[frameIdx];
                const prog=document.getElementById('vidProgress');
                if(prog)prog.style.width=((frameIdx+1)/frames.length*100)+'%';
                const fc=document.getElementById('vidFrameCount');
                if(fc)fc.textContent='Frame '+(frameIdx+1)+'/'+frames.length;
            },100);
        }else{
            btn.textContent='▶ Play';
            if(videoPlaybackTimer)clearInterval(videoPlaybackTimer);
        }
    };
}

/* ==================== SETTINGS APP ==================== */
function renderSettingsApp(){
    appTitle.textContent='Settings';
    appContent.innerHTML=`
        <div class="setting-item"><span>Airplane Mode</span><span class="setting-value">Off</span></div>
        <div class="setting-item"><span>Wi-Fi</span><span class="setting-value">Connected</span></div>
        <div class="setting-item"><span>Bluetooth</span><span class="setting-value">On</span></div>
        <div class="setting-item"><span>Battery</span><span class="setting-value">${battery}%</span></div>
        <div class="setting-item"><span>Dark Mode</span><span class="setting-value">On</span></div>
        <div class="setting-item"><span>Storage</span><span class="setting-value">${photos.length||0} photos · ${messages.length||0} messages</span></div>
        <div class="setting-item"><span>Phone Number</span><span class="setting-value" id="myPhoneNumber">—</span></div>
    `;
    fetch(`https://${GetParentResourceName()}/getMyNumber`,{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'}).then(r=>r.json()).then(d=>{
        const el=document.getElementById('myPhoneNumber');if(el&&d.number)el.textContent=d.number;
    }).catch(()=>{});
}

/* ==================== GPS APP ==================== */
function renderGpsApp(){
    appTitle.textContent='GPS';
    const locations=[
        {name:'Legion Square',desc:'Downtown Los Santos',coords:'{x=200.0,y=-800.0,z=30.0}'},
        {name:'LSIA',desc:'Los Santos International Airport',coords:'{x=-1040.0,y=-2750.0,z=14.0}'},
        {name:'Sandy Shores',desc:"Simpson's Desert",coords:'{x=1502.0,y=3921.0,z=31.0}'},
        {name:'Paleto Bay',desc:'Blaine County',coords:'{x=-167.0,y=6470.0,z=32.0}'},
        {name:'Mount Chiliad',desc:'Highest peak',coords:'{x=500.0,y=5600.0,z=800.0}'},
        {name:'Vespucci Beach',desc:'West Coast',coords:'{x=-1210.0,y=-1510.0,z=4.0}'},
    ];
    let html=`<input class="gps-search" id="gpsSearch" placeholder="Search places..." oninput="filterGps(this.value)" />
    <div id="gpsResults">`;
    locations.forEach(l=>{
        html+=`<div class="gps-location" onclick="navigateTo('${l.name}')">
            <div class="gps-loc-name">${l.name}</div><div class="gps-loc-desc">${l.desc}</div>
        </div>`;
    });
    html+=`</div><button class="gps-nav-btn" onclick="gpsMyLocation()">📍 My Location</button>`;
    appContent.innerHTML=html;
}

function navigateTo(name){
    fetch(`https://${GetParentResourceName()}/gpsNavigate`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({destination:name})});
    Wrappers.Notify('Navigating to '+name,'info');
}

function gpsMyLocation(){
    fetch(`https://${GetParentResourceName()}/gpsMyLocation`,{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'});
    Wrappers.Notify('Showing your location','info');
}

function filterGps(val){
    const items=document.querySelectorAll('.gps-location');
    items.forEach(item=>{
        const name=item.querySelector('.gps-loc-name')?.textContent||'';
        item.style.display=name.toLowerCase().includes(val.toLowerCase())?'block':'none';
    });
}

/* ==================== CLOCK APP ==================== */
function renderClockApp(){
    appTitle.textContent='Clock';
    const now=new Date();
    appContent.innerHTML=`
        <div class="clock-face">
            <div class="clock-digital">${now.getHours().toString().padStart(2,'0')}:${now.getMinutes().toString().padStart(2,'0')}</div>
            <div class="clock-date">${now.toLocaleDateString('en-US',{weekday:'long',month:'long',day:'numeric'})}</div>
        </div>
        <div class="clock-alarms"><div style="text-align:center;color:rgba(255,255,255,0.2);padding:20px;font-size:13px">No alarms set</div></div>
    `;
}

/* ==================== NOTES APP ==================== */
function renderNotesApp(){
    appTitle.textContent='Notes';
    let html='<textarea class="note-input" id="noteInput" placeholder="Write a note..."></textarea><button class="note-save" id="noteSave">Save</button><div style="margin-top:16px">';
    notes.forEach(n=>{
        html+=`<div class="note-item">${n.content||n}<div class="note-time">${n.time?new Date(n.time*1000).toLocaleDateString():''}</div></div>`;
    });
    html+='</div>';
    appContent.innerHTML=html;
    document.getElementById('noteSave').addEventListener('click',function(){
        const input=document.getElementById('noteInput');
        if(input.value.trim()){
            fetch(`https://${GetParentResourceName()}/saveNote`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({content:input.value})});
            notes.push({content:input.value,time:Math.floor(Date.now()/1000)});
            input.value='';renderNotesApp();
        }
    });
}

/* ==================== CONTACT CARD APP ==================== */
function renderContactCardApp(){
    appTitle.textContent='My Card';
    fetch(`https://${GetParentResourceName()}/getMyCard`,{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'}).then(r=>r.json()).then(d=>{
        const name=d.name||'Player';const number=d.number||'—';
        const initial=name.charAt(0).toUpperCase();
        appContent.innerHTML=`
            <div class="mycard">
                <div class="mycard-avatar">${initial}</div>
                <div class="mycard-name">${name}</div>
                <div class="mycard-number">${number}</div>
                <button class="mycard-share" onclick="shareMyCard()">Share Contact</button>
            </div>
        `;
    }).catch(()=>{
        appContent.innerHTML='<div class="mycard"><div class="mycard-avatar">?</div><div class="mycard-name">Unknown</div><div class="mycard-number">—</div></div>';
    });
}

function shareMyCard(){
    fetch(`https://${GetParentResourceName()}/getMyCard`,{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'}).then(r=>r.json()).then(d=>{
        Wrappers.Notify('Shared: '+d.name+' | '+d.number,'success');
    }).catch(()=>{});
}

/* ==================== LOCATOR APP ==================== */
function renderLocatorApp(){
    appTitle.textContent='Find My';
    if(contacts.length===0){
        appContent.innerHTML='<div style="text-align:center;padding:60px 0;color:rgba(255,255,255,0.2);font-size:13px">No contacts to locate</div>';
        return;
    }
    let html='';
    contacts.forEach(c=>{
        html+=`<div class="locator-item">
            <div class="locator-icon">📍</div>
            <div class="locator-name">${c.name||c.number||'Unknown'}</div>
            <div class="locator-dist">Online</div>
        </div>`;
    });
    appContent.innerHTML=html;
}

/* ==================== VPN APP ==================== */
function renderVpnApp(){
    appTitle.textContent='VPN';
    const regions=['US East','US West','UK London','Germany','Netherlands','Japan','Australia'];
    let html=`
        <div class="vpn-status">
            <div class="vpn-dot disconnected"></div>
            <span class="vpn-text">Disconnected</span>
        </div>
        <button class="note-save" onclick="toggleVpn()" style="width:100%;margin-bottom:16px">Connect</button>
        <div style="color:rgba(255,255,255,0.3);font-size:11px;margin-bottom:8px">REGIONS</div>
    `;
    regions.forEach(r=>{html+=`<div class="vpn-region" onclick="selectVpnRegion('${r}')">${r}</div>`;});
    appContent.innerHTML=html;
}

let vpnConnected=false;
function toggleVpn(){
    vpnConnected=!vpnConnected;
    const status=document.querySelector('.vpn-status');
    const btn=document.querySelector('.note-save');
    if(status){const dot=status.querySelector('.vpn-dot');if(dot){dot.className='vpn-dot '+(vpnConnected?'connected':'disconnected');}
    status.querySelector('.vpn-text').textContent=vpnConnected?'Connected':'Disconnected';}
    if(btn)btn.textContent=vpnConnected?'Disconnect':'Connect';
    Wrappers.Notify(vpnConnected?'VPN Connected':'VPN Disconnected',vpnConnected?'success':'info');
}

function selectVpnRegion(region){Wrappers.Notify('Connecting to '+region+'...','info');setTimeout(()=>{if(!vpnConnected)toggleVpn();},1000);}

/* ==================== VEHICLES APP ==================== */
let vehicleLockStates={};
let vehicleEngineStates={};
function renderVehiclesApp(){
    appTitle.textContent='Vehicles';
    appContent.innerHTML='<div style="text-align:center;padding:40px;color:rgba(255,255,255,0.2)">Loading vehicles...</div>';
    fetch(`https://${GetParentResourceName()}/phoneGarageGetVehicles`,{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'})
        .then(r=>r.json()).then(vs=>{
            if(!vs||vs.length===0){appContent.innerHTML='<div style="text-align:center;padding:60px 0;color:rgba(255,255,255,0.2);font-size:13px">No vehicles owned</div>';return;}
            let html='<div class="vehicles-scroll">';
            vs.forEach(v=>{
                const stateClass=v.state==='out'?'state-out':'state-stored';
                const stateIcon=v.state==='out'?'🚗':(v.state==='impounded'?'⚠️':'🏠');
                const loc=v.state==='stored'?('Garage: '+(v.garage||'Unknown')):'Spawned in world';
                const fuelPct=v.fuel||100;
                const fuelColor=fuelPct>50?'#32c832':(fuelPct>20?'#ffc832':'#ff3b30');
                html+=`
                    <div class="vehicle-card ${v.state==='impounded'?'vehicle-impounded':''}">
                        <div class="vehicle-header">
                            <div class="vehicle-model">${v.model}</div>
                            <div class="vehicle-state ${stateClass}">${stateIcon} ${v.state.charAt(0).toUpperCase()+v.state.slice(1)}</div>
                        </div>
                        <div class="vehicle-plate">${v.plate}</div>
                        <div class="vehicle-fuel-row"><div class="vehicle-fuel-bar"><div class="vehicle-fuel-fill" style="width:${fuelPct}%;background:${fuelColor}"></div></div><span class="vehicle-fuel-text">${fuelPct}%</span></div>
                        <div class="vehicle-info">${loc}</div>
                        <div class="vehicle-actions">
                            <button class="vehicle-btn" onclick="vehicleToggleLock('${v.plate}',this)">${vehicleLockStates[v.plate]?'🔓':'🔒'} Lock</button>
                            <button class="vehicle-btn vehicle-btn-engine" onclick="vehicleToggleEngine('${v.plate}',this)" ${v.state!=='out'?'disabled':''}>⚡ Engine</button>
                            <button class="vehicle-btn vehicle-btn-track" onclick="vehicleTrack('${v.plate}')" ${v.state!=='out'?'disabled':''}>📍 Track</button>
                        </div>
                    </div>
                `;
            });
            html+='</div>';
            appContent.innerHTML=html;
        }).catch(()=>{appContent.innerHTML='<div style="text-align:center;padding:60px 0;color:rgba(255,255,255,0.2);font-size:13px">Failed to load</div>';});
}

function vehicleToggleLock(plate,btn){
    btn.textContent='...';btn.disabled=true;
    fetch(`https://${GetParentResourceName()}/phoneGarageToggleLock`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({plate:plate})})
        .then(r=>r.json()).then(d=>{
            if(d&&d.success){vehicleLockStates[plate]=d.locked;Wrappers.Notify(d.locked?'🔒 Locked':'🔓 Unlocked','success');}
            else{Wrappers.Notify(d&&d.error||'Failed','error');}
            renderVehiclesApp();
        }).catch(()=>{renderVehiclesApp();});
}

function vehicleToggleEngine(plate,btn){
    btn.textContent='...';btn.disabled=true;
    fetch(`https://${GetParentResourceName()}/phoneGarageToggleEngine`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({plate:plate})})
        .then(r=>r.json()).then(d=>{
            if(d&&d.success){vehicleEngineStates[plate]=d.engineOn;Wrappers.Notify(d.engineOn?'⚡ Engine started':'⏹ Engine off','success');}
            else{Wrappers.Notify(d&&d.error||'Failed','error');}
            renderVehiclesApp();
        }).catch(()=>{renderVehiclesApp();});
}

function vehicleTrack(plate){
    fetch(`https://${GetParentResourceName()}/phoneGarageTrackVehicle`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({plate:plate})})
        .then(r=>r.json()).then(d=>{
            if(d&&d.success)Wrappers.Notify('📍 Waypoint set to vehicle','success');
            else Wrappers.Notify(d&&d.error||'Cannot track','error');
        });
}

/* ==================== SAFARI (WEB BROWSER) ==================== */
function renderBrowserApp(){
    appTitle.textContent='Safari';
    appContent.innerHTML=`
        <div class="browser-bar"><input class="browser-url" id="browserUrl" placeholder="Search or enter URL" value="https://google.com" /><button class="browser-go" onclick="browserNavigate()">Go</button></div>
        <div class="browser-nav"><button class="browser-nav-btn" onclick="browserBack()">←</button><button class="browser-nav-btn" onclick="browserForward()">→</button><button class="browser-nav-btn" onclick="browserRefresh()">↻</button></div>
        <iframe class="browser-frame" id="browserFrame" src="https://google.com" sandbox="allow-scripts allow-same-origin allow-forms" loading="lazy"></iframe>
    `;
    document.getElementById('browserUrl').addEventListener('keydown',function(e){if(e.key==='Enter')browserNavigate();});
}
let browserHistory=['https://google.com'];let browserHistoryIdx=0;
function browserNavigate(){
    const url=document.getElementById('browserUrl')?.value||'https://google.com';
    let finalUrl=url;
    if(!url.startsWith('http://')&&!url.startsWith('https://'))finalUrl='https://'+url;
    const frame=document.getElementById('browserFrame');
    if(frame)frame.src=finalUrl;
    if(browserHistoryIdx<browserHistory.length-1)browserHistory=browserHistory.slice(0,browserHistoryIdx+1);
    browserHistory.push(finalUrl);browserHistoryIdx=browserHistory.length-1;
}
function browserBack(){if(browserHistoryIdx>0){browserHistoryIdx--;const frame=document.getElementById('browserFrame');if(frame)frame.src=browserHistory[browserHistoryIdx];const url=document.getElementById('browserUrl');if(url)url.value=browserHistory[browserHistoryIdx];}}
function browserForward(){if(browserHistoryIdx<browserHistory.length-1){browserHistoryIdx++;const frame=document.getElementById('browserFrame');if(frame)frame.src=browserHistory[browserHistoryIdx];const url=document.getElementById('browserUrl');if(url)url.value=browserHistory[browserHistoryIdx];}}
function browserRefresh(){const frame=document.getElementById('browserFrame');if(frame)frame.src=frame.src;}

/* ==================== CALCULATOR ==================== */
let calcDisplay='0';let calcMemory=null;let calcOp=null;let calcReset=false;
function renderCalculatorApp(){
    appTitle.textContent='Calculator';
    let html=`<div class="calc-display" id="calcDisplay">${calcDisplay}</div><div class="calc-grid">`;
    const btns=[['C','±','%','÷'],['7','8','9','×'],['4','5','6','−'],['1','2','3','+'],['0','.','⌫','=']];
    btns.forEach(row=>{row.forEach(b=>{const cls=b==='='?'calc-eq':(isNaN(b)&&b!=='.'?'calc-op':'calc-num');html+=`<button class="calc-btn ${cls}" onclick="calcPress('${b}')">${b}</button>`;});});
    html+=`</div>`;
    appContent.innerHTML=html;
}
function calcPress(val){
    const d=document.getElementById('calcDisplay');
    if(val==='C'){calcDisplay='0';calcMemory=null;calcOp=null;calcReset=false;}
    else if(val==='⌫'){calcDisplay=calcDisplay.length>1?calcDisplay.slice(0,-1):'0';}
    else if(val==='±'){calcDisplay=String(-parseFloat(calcDisplay));}
    else if(val==='%'){calcDisplay=String(parseFloat(calcDisplay)/100);}
    else if(['+','−','×','÷'].includes(val)){
        if(calcMemory!==null&&calcOp)calcDisplay=String(calcCalculate());
        calcMemory=parseFloat(calcDisplay);calcOp=val;calcReset=true;
    }
    else if(val==='='){
        if(calcMemory!==null&&calcOp){calcDisplay=String(calcCalculate());calcMemory=null;calcOp=null;}
        calcReset=true;
    }
    else{
        if(calcReset||calcDisplay==='0'){calcDisplay=val;calcReset=false;}
        else calcDisplay+=val;
    }
    if(d)d.textContent=calcDisplay;
}
function calcCalculate(){
    const a=calcMemory,b=parseFloat(calcDisplay);
    switch(calcOp){
        case'+':return a+b;case'−':return a-b;case'×':return a*b;case'÷':return b!==0?a/b:'Error';
        default:return b;
    }
}

/* ==================== CALENDAR ==================== */
let calView='month';let calDate=new Date();
function renderCalendarApp(){
    appTitle.textContent='Calendar';
    fetch(`https://${GetParentResourceName()}/calendarGetEvents`,{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'});
    let html=`<div class="cal-nav"><button class="cal-nav-btn" onclick="calMonthOffset(-1)">←</button><span class="cal-nav-title">${calDate.toLocaleDateString('en-US',{month:'long',year:'numeric'})}</span><button class="cal-nav-btn" onclick="calMonthOffset(1)">→</button></div>`;
    html+=`<div class="cal-grid">`;
    ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'].forEach(d=>{html+=`<div class="cal-grid-hd">${d}</div>`;});
    const y=calDate.getFullYear(),m=calDate.getMonth();
    const firstDay=new Date(y,m,1).getDay();
    const daysInMonth=new Date(y,m+1,0).getDate();
    for(let i=0;i<firstDay;i++)html+=`<div class="cal-grid-day empty"></div>`;
    for(let d=1;d<=daysInMonth;d++){
        const today=(new Date().getDate()===d&&new Date().getMonth()===m&&new Date().getFullYear()===y);
        const evts=calEvents.filter(e=>{try{const ed=new Date(e.event_date);return ed.getDate()===d&&ed.getMonth()===m&&ed.getFullYear()===y;}catch(ex){return false;}});
        html+=`<div class="cal-grid-day ${today?'today':''}" onclick="calShowDay(${y},${m},${d})">${d}${evts.length>0?`<div class="cal-dot"></div>`:''}</div>`;
    }
    html+=`</div>`;
    html+=`<button class="note-save" onclick="calAddEvent()" style="width:100%;margin-top:8px">+ Add Event</button>`;
    html+=`<div id="calEvents" style="margin-top:8px"></div>`;
    appContent.innerHTML=html;
    renderCalEvents();
}
function calMonthOffset(off){calDate.setMonth(calDate.getMonth()+off);renderCalendarApp();}
function calShowDay(y,m,d){calDate=new Date(y,m,d);calView='day';renderCalendarApp();}
function calAddEvent(){
    appContent.innerHTML=`
        <div style="padding:8px 0"><input class="msg-input" id="calTitle" placeholder="Event title" style="margin-bottom:8px"/></div>
        <textarea class="x-textarea" id="calDesc" placeholder="Description" style="margin-bottom:8px"></textarea>
        <div style="display:flex;gap:8px;margin-bottom:8px"><input class="msg-input" id="calDate" type="date" style="flex:1" value="${calDate.toISOString().split('T')[0]}"/><input class="msg-input" id="calTime" type="time" style="flex:1" value="12:00"/></div>
        <button class="taxi-accept-btn" onclick="calSaveEvent()">Save Event</button>
        <button class="note-save" onclick="renderCalendarApp()" style="margin-top:4px">Cancel</button>
    `;
}
function calSaveEvent(){
    const t=document.getElementById('calTitle')?.value,d=document.getElementById('calDesc')?.value,dt=document.getElementById('calDate')?.value,ti=document.getElementById('calTime')?.value;
    if(!t||!dt){Wrappers.Notify('Title and date required','error');return;}
    fetch(`https://${GetParentResourceName()}/calendarSaveEvent`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({title:t,description:d||'',date:dt,time:ti||'12:00'})});
    Wrappers.Notify('Event saved!','success');setTimeout(()=>renderCalendarApp(),300);
}
function renderCalEvents(){
    const el=document.getElementById('calEvents');if(!el)return;
    const todayEvents=calEvents.filter(e=>{try{const ed=new Date(e.event_date);return ed.getDate()===calDate.getDate()&&ed.getMonth()===calDate.getMonth()&&ed.getFullYear()===calDate.getFullYear();}catch(ex){return false;}});
    if(!todayEvents||todayEvents.length===0){el.innerHTML='<div style="text-align:center;padding:16px;color:rgba(255,255,255,0.2);font-size:12px">No events this day</div>';return;}
    let html=todayEvents.map(e=>`<div class="cal-event-item"><div class="cal-event-color" style="background:${e.color||'#007AFF'}"></div><div class="cal-event-info"><div class="cal-event-title">${e.title||'Event'}</div><div class="cal-event-time">${e.event_time||'12:00'}</div></div><button class="cal-event-del" onclick="calDeleteEvent(${e.id})">✕</button></div>`).join('');
    el.innerHTML=html;
}

function calDeleteEvent(id){
    fetch(`https://${GetParentResourceName()}/calendarDeleteEvent`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({eventId:id})});
    Wrappers.Notify('Event deleted','info');setTimeout(()=>renderCalendarApp(),300);
}

/* ==================== WALLET ==================== */
function renderWalletApp(){
    appTitle.textContent='Wallet';
    fetch(`https://${GetParentResourceName()}/walletGetCards`,{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'});
    let html='<div class="wallet-cards" id="walletCards"></div>';
    html+=`<button class="note-save" onclick="walletAddCard()" style="width:100%;margin-top:8px">+ Add Card</button>`;
    appContent.innerHTML=html;
    renderWalletCards();
}
function renderWalletCards(){
    const el=document.getElementById('walletCards');if(!el)return;
    if(!walletCards||walletCards.length===0){el.innerHTML='<div style="text-align:center;padding:40px;color:rgba(255,255,255,0.2);font-size:13px">No cards yet</div>';return;}
    let html=walletCards.map(c=>`<div class="wallet-card" style="background:linear-gradient(135deg,${c.color||'#007AFF'},${c.color||'#0055FF'})">
        <div class="wallet-card-type">${c.card_type||'Card'}</div>
        <div class="wallet-card-number">${c.card_number||'****'}</div>
        <div class="wallet-card-holder">${c.holder_name||''}</div>
        <button class="wallet-card-del" onclick="walletDeleteCard(${c.id})">✕</button>
    </div>`).join('');
    el.innerHTML=html;
}
function walletAddCard(){
    appContent.innerHTML=`
        <div style="padding:8px 0">
            <select class="msg-input" id="walletCardType" style="margin-bottom:8px">
                <option value="ID Card">ID Card</option>
                <option value="Driver License">Driver License</option>
                <option value="Weapon License">Weapon License</option>
                <option value="Bank Card">Bank Card</option>
                <option value="Membership">Membership</option>
            </select>
            <input class="msg-input" id="walletCardNumber" placeholder="Card number (optional)" style="margin-bottom:8px"/>
            <input class="msg-input" id="walletHolderName" placeholder="Holder name (optional)" style="margin-bottom:12px"/>
            <button class="taxi-accept-btn" onclick="walletSaveCard()">Save Card</button>
            <button class="note-save" onclick="renderWalletApp()" style="margin-top:4px">Cancel</button>
        </div>
    `;
}
function walletSaveCard(){
    const ct=document.getElementById('walletCardType')?.value,cn=document.getElementById('walletCardNumber')?.value,hn=document.getElementById('walletHolderName')?.value;
    if(!ct){Wrappers.Notify('Select card type','error');return;}
    fetch(`https://${GetParentResourceName()}/walletAddCard`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({cardType:ct,cardNumber:cn||'****',holderName:hn||''})});
    Wrappers.Notify('Card added!','success');setTimeout(()=>renderWalletApp(),300);
}
function walletDeleteCard(id){
    if(!confirm('Delete this card?'))return;
    fetch(`https://${GetParentResourceName()}/walletDeleteCard`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({cardId:id})});
    Wrappers.Notify('Card deleted','info');setTimeout(()=>renderWalletApp(),300);
}

/* Keep music stub but don't register it in config */
function renderMusicApp(){}
function renderAppStoreApp(){}

/* ==================== CALLING SYSTEM ==================== */
function showIncomingCall(caller,callerName){
    const name=callerName||caller||'Unknown';
    incallAvatar.textContent=name.charAt(0).toUpperCase();
    incallName.textContent=name;
    incomingCall.classList.remove('hidden');
    appHome.classList.add('hidden');appView.classList.add('hidden');
}

function hideIncomingCall(){incomingCall.classList.add('hidden');}

acceptBtn.addEventListener('click',function(){
    fetch(`https://${GetParentResourceName()}/answerCall`,{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'});
    hideIncomingCall();
});

declineBtn.addEventListener('click',function(){
    fetch(`https://${GetParentResourceName()}/rejectCall`,{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'});
    hideIncomingCall();
});

function startActiveCall(peer,peerName){
    hideIncomingCall();
    callState.active=true;callState.peer=peer;callState.peerName=peerName||peer||'Unknown';callState.seconds=0;
    actcallAvatar.textContent=(callState.peerName||'?').charAt(0).toUpperCase();
    actcallName.textContent=callState.peerName;
    actcallDuration.textContent='00:00';
    activeCall.classList.remove('hidden');
    appHome.classList.add('hidden');appView.classList.add('hidden');
    if(callState.timer)clearInterval(callState.timer);
    callState.timer=setInterval(()=>{callState.seconds++;actcallDuration.textContent=formatTime(callState.seconds);},1000);
    voiceCallBadge.style.display='flex';
    callPeerName.textContent=callState.peerName;
}

function hideActiveCall(){
    activeCall.classList.add('hidden');
    callState.active=false;callState.peer=null;callState.peerName=null;callState.seconds=0;
    if(callState.timer){clearInterval(callState.timer);callState.timer=null;}
    voiceCallBadge.style.display='none';
}

endCallBtn.addEventListener('click',function(){
    fetch(`https://${GetParentResourceName()}/endCall`,{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'});
    hideActiveCall();
});

callMuteBtn.addEventListener('click',function(){
    callState.muted=!callState.muted;
    callMuteBtn.classList.toggle('active',callState.muted);
    callMuteBtn.querySelector('span').textContent=callState.muted?'Unmute':'Mute';
    fetch(`https://${GetParentResourceName()}/toggleMute`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({muted:callState.muted})});
});

callSpeakerBtn.addEventListener('click',function(){
    callState.speaker=!callState.speaker;
    callSpeakerBtn.classList.toggle('active',callState.speaker);
    callSpeakerBtn.querySelector('span').textContent=callState.speaker?'Speaker On':'Speaker';
    fetch(`https://${GetParentResourceName()}/toggleSpeaker`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({enabled:callState.speaker})});
});

callKeypadBtn.addEventListener('click',function(){
    Wrappers.Notify('DTMF keypad','info');
});

function cleanupCall(){
    if(callState.active){hideActiveCall();}
    hideIncomingCall();
}

/* ==================== TAXI APP ==================== */
let taxiState={isDriver:false,onDuty:false,activeRide:null,passengerRating:0,driverRating:0};

function renderTaxiApp(){
    appTitle.textContent='Taxi';
    let html='<div class="taxi-container">';
    if(taxiState.activeRide){
        const ride=taxiState.activeRide;
        html+=`<div class="taxi-card" style="border:1px solid rgba(39,201,63,0.3)">
            <div class="taxi-card-title">🚕 Active Ride</div>
            <div class="taxi-fare-item"><span class="taxi-fare-label">Distance</span><span class="taxi-fare-value">${(ride.distance||0).toFixed(2)} mi</span></div>
            <div class="taxi-fare-item"><span class="taxi-fare-label">Current Fare</span><span class="taxi-fare-value">$${(ride.fare||0).toFixed(2)}</span></div>
            <div class="taxi-fare-item"><span class="taxi-fare-label">Passenger</span><span class="taxi-fare-value">${ride.passenger||'—'}</span></div>
            <button class="taxi-accept-btn" onclick="endTaxiRide()">Complete Ride</button>
        </div>`;
    }else{
        const onDuty=taxiState.onDuty;
        html+=`<div class="taxi-status">
            <div class="taxi-status-dot ${onDuty?'on':'off'}"></div>
            <span class="taxi-status-text">${onDuty?'On Duty':'Off Duty'}</span>
            <button class="taxi-toggle-btn ${onDuty?'on':'off'}" onclick="toggleTaxiDuty()">${onDuty?'Go Offline':'Go Online'}</button>
        </div>`;
        if(onDuty){
            html+=`<div class="taxi-section-title">Available Fares</div><div class="taxi-empty">Waiting for dispatch...</div>`;
            if(taxiState.driverRating>0){
                html+=`<div class="taxi-section-title">Your Rating</div><div style="display:flex;gap:4px">`;
                for(let i=1;i<=5;i++)html+=`<span class="taxi-star ${i<=taxiState.driverRating?'active':''}" style="font-size:20px">★</span>`;
                html+=`</div>`;
            }
        }else{
            html+=`<div class="taxi-card" onclick="openPassengerRequest()">
                <div class="taxi-card-title">Request a Taxi</div>
                <div class="taxi-card-sub">Get picked up anywhere in the city</div>
                <div class="taxi-card-price">From $3.50</div>
            </div>
            <div style="margin-top:12px;background:rgba(255,255,255,0.03);border-radius:16px;padding:16px">
                <div class="taxi-fare-item"><span class="taxi-fare-label">Base Fare</span><span class="taxi-fare-value">$3.50</span></div>
                <div class="taxi-fare-item"><span class="taxi-fare-label">Per Mile</span><span class="taxi-fare-value">$2.00</span></div>
            </div>`;
        }
    }
    html+='</div>';
    appContent.innerHTML=html;
}

function toggleTaxiDuty(){
    taxiState.onDuty=!taxiState.onDuty;
    fetch(`https://${GetParentResourceName()}/taxiToggleDuty`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({onDuty:taxiState.onDuty})});
    renderTaxiApp();
}

function openPassengerRequest(){
    fetch(`https://${GetParentResourceName()}/taxiRequest`,{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'});
}

function endTaxiRide(){
    fetch(`https://${GetParentResourceName()}/taxiEndRide`,{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'});
    let rateHtml='<div style="text-align:center;padding:20px"><div style="font-size:16px;color:#fff;margin-bottom:16px">Rate your driver</div><div class="taxi-rating">';
    for(let i=1;i<=5;i++)rateHtml+=`<span class="taxi-star" data-rate="${i}" onclick="rateDriver(${i})">★</span>`;
    rateHtml+='</div></div>';
    appContent.innerHTML=rateHtml;
}

function rateDriver(rating){
    taxiState.passengerRating=rating;
    fetch(`https://${GetParentResourceName()}/taxiRateDriver`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({rating})});
    taxiState.activeRide=null;
    renderTaxiApp();
}

function showTaxiDispatch(data){
    if(!taxiState.onDuty)return;
    if(data.fare){taxiState.activeRide=taxiState.activeRide||{};Object.assign(taxiState.activeRide,data.fare);renderTaxiApp();}
}

/* ==================== BLACKCHAT (UNTRACEABLE GANG MSG) ==================== */
let bcSelectedChat = null;
function renderBlackChatApp(){
    appTitle.textContent='BlackChat';
    if(bcSelectedChat){
        renderBCConversation();return;
    }
    let html=`<div class="new-msg-btn" onclick="showBCNewChat()" style="background:#2a2a3e;padding:12px;border-radius:12px;text-align:center;color:rgba(255,255,255,0.6);cursor:pointer;margin-bottom:8px">✏️ New Chat</div>
    <div class="new-msg-btn" onclick="showBCNewGroup()" style="margin-top:4px;background:#2a2a3e;padding:12px;border-radius:12px;text-align:center;color:rgba(255,255,255,0.6);cursor:pointer;margin-bottom:8px">👥 New Group</div>
    <div id="bcChatList"></div>`;
    appContent.innerHTML=html;
    const list=document.getElementById('bcChatList');
    if(!list)return;
    if(!blackChats||blackChats.length===0){
        list.innerHTML='<div style="text-align:center;padding:60px 0;color:rgba(255,255,255,0.15);font-size:13px">🔒 No encrypted chats</div>';
        return;
    }
    blackChats.forEach(chat=>{
        const lastMsg=chat.messages&&chat.messages.length>0?chat.messages[chat.messages.length-1]:null;
        const isGroup=chat.type==='group';
        const avatar=isGroup?(chat.name||'G').charAt(0).toUpperCase():(chat.peer||'?').charAt(0).toUpperCase();
        const name=isGroup?chat.name:chat.peer||'Unknown';
        const preview=lastMsg?lastMsg.content:'';
        const div=document.createElement('div');div.className='msg-conv';
        div.style.borderBottom='1px solid rgba(255,255,255,0.04)';
        div.innerHTML=`<div class="msg-conv-avatar" style="background:${isGroup?'#2C2C3E':'#1a1a2e'}">${avatar}</div>
            <div class="msg-conv-info"><div class="msg-conv-name" style="color:#aaa">${name}</div>
            <div class="msg-conv-preview" style="color:rgba(255,255,255,0.3)">${preview||'🔒 Encrypted'}</div></div>
            ${isGroup?`<div style="font-size:10px;color:rgba(255,255,255,0.2)">${(chat.members||[]).length}m</div>`:''}
        `;
        div.addEventListener('click',()=>{bcSelectedChat=chat.id;renderBlackChatApp();});
        list.appendChild(div);
    });
}

function showBCNewChat(){
    appContent.innerHTML=`
        <div style="padding:8px 0"><input class="msg-input" id="bcNewPeer" placeholder="Enter number" style="margin-bottom:12px;background:#1e1e2e;border-color:#333;color:#aaa" /></div>
        <button class="taxi-accept-btn" onclick="startBCConversation()" style="background:#2a2a3e">Start Encrypted Chat</button>
    `;
}

function startBCConversation(){
    const num=document.getElementById('bcNewPeer')?.value;
    if(!num){Wrappers.Notify('Enter a number','error');return;}
    const existing=blackChats.find(c=>c.type==='direct'&&c.peer===num);
    if(existing){bcSelectedChat=existing.id;renderBlackChatApp();return;}
    const cid='bc_'+Date.now();
    fetch(`https://${GetParentResourceName()}/bcStartChat`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({peer:num})});
    blackChats.push({id:cid,type:'direct',peer:num,messages:[]});
    bcSelectedChat=cid;renderBlackChatApp();
}

function showBCNewGroup(){
    let html='<div style="padding:8px 0"><input class="msg-input" id="bcGroupName" placeholder="Encrypted group name" style="margin-bottom:8px;background:#1e1e2e;border-color:#333;color:#aaa" /></div>';
    html+='<div style="color:rgba(255,255,255,0.2);font-size:11px;margin:8px 0">Add contacts (encrypted)</div>';
    (contacts||[]).forEach(c=>{
        html+=`<label style="display:flex;align-items:center;gap:12px;padding:8px 0;cursor:pointer">
            <input type="checkbox" class="bc-member-cb" value="${c.number||''}" />
            <div class="contact-avatar" style="width:28px;height:28px;font-size:12px;background:#2a2a3e">${c.name.charAt(0).toUpperCase()}</div>
            <span style="color:#aaa;font-size:13px">${c.name}</span>
        </label>`;
    });
    html+=`<button class="taxi-accept-btn" onclick="createBCGroup()" style="margin-top:12px;background:#2a2a3e">Create Encrypted Group</button>`;
    appContent.innerHTML=html;
}

function createBCGroup(){
    const name=document.getElementById('bcGroupName')?.value||'Encrypted';
    const cbs=document.querySelectorAll('.bc-member-cb:checked');
    const members=[];cbs.forEach(cb=>{if(cb.value)members.push(cb.value);});
    if(members.length<1){Wrappers.Notify('Add at least 1 member','error');return;}
    const gid='bcg_'+Date.now();
    fetch(`https://${GetParentResourceName()}/bcCreateGroup`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({name,members})});
    blackChats.push({id:gid,type:'group',name,members,messages:[]});
    bcSelectedChat=gid;renderBlackChatApp();
}

function renderBCConversation(){
    const chat=blackChats.find(c=>c.id===bcSelectedChat);
    if(!chat){appContent.innerHTML='<div>Chat not found</div>';return;}
    appTitle.textContent=chat.type==='group'?chat.name:chat.peer||'BlackChat';
    const msgs=chat.messages||[];
    let html='<div class="msg-list" id="bcMsgList">';
    msgs.forEach(m=>{
        const cls=m.incoming?'msg-incoming':'msg-outgoing';
        let body='';
        if(m.content)body+=m.content;
        if(m.image)body+=`<img src="${m.image}" class="msg-image" />`;
        if(m.video)body+=`<video src="${m.video}" class="msg-video" controls></video>`;
        html+=`<div class="msg-bubble ${cls}" style="${m.incoming?'background:#2a2a3e;border-color:#333':'background:#1a1a2e;border-color:#2a2a3e'}">${body}<span class="msg-time">${m.time?formatMsgTime(m.time):''}</span></div>`;
    });
    html+=`</div><div class="msg-input-wrap">
        <input class="msg-input" id="bcMsgInput" placeholder="🔒 Encrypted" style="background:#1e1e2e;border-color:#333;color:#aaa" />
        <button class="msg-attach" id="bcMsgAttach" title="Attach image">📷</button>
        <button class="msg-send" id="bcMsgSend">Send</button>
    </div>`;
    appContent.innerHTML=html;
    appTitle.parentElement.querySelector('.back-btn').onclick=function(){bcSelectedChat=null;renderBlackChatApp();};
    const list=document.getElementById('bcMsgList');if(list)list.scrollTop=list.scrollHeight;
    document.getElementById('bcMsgAttach').addEventListener('click',function(){
        const input=document.createElement('input');input.type='file';input.accept='image/*';
        input.onchange=function(e){
            const file=e.target.files[0];if(!file)return;
            const reader=new FileReader();
            reader.onload=function(ev){
                const dataUrl=ev.target.result;
                const target=chat.type==='group'?`/bcSendGroupImage`:`/bcSendImage`;
                const body=chat.type==='group'?JSON.stringify({groupId:chat.id,image:dataUrl}):JSON.stringify({peer:chat.peer,image:dataUrl});
                fetch(`https://${GetParentResourceName()}${target}`,{method:'POST',headers:{'Content-Type':'application/json'},body});
                chat.messages.push({image:dataUrl,incoming:false,time:Date.now()/1000});
                renderBCConversation();
            };
            reader.readAsDataURL(file);
        };
        input.click();
    });
    document.getElementById('bcMsgSend').addEventListener('click',function(){
        const input=document.getElementById('bcMsgInput');
        if(input.value.trim()){
            const target=chat.type==='group'?`/bcSendGroupMessage`:`/bcSendMessage`;
            const body=chat.type==='group'?JSON.stringify({groupId:chat.id,content:input.value}):JSON.stringify({peer:chat.peer,content:input.value});
            fetch(`https://${GetParentResourceName()}${target}`,{method:'POST',headers:{'Content-Type':'application/json'},body});
            chat.messages.push({content:input.value,incoming:false,time:Date.now()/1000});
            input.value='';renderBCConversation();
        }
    });
}

/* ==================== NUI HANDLERS FOR GROUP & BLACKCHAT ==================== */
window.addEventListener('message',function(event){
    const d=event.data;
    if(d.action==='bcNewMessage'){
        let chat=blackChats.find(c=>c.id===d.chatId);
        if(!chat)chat=blackChats.find(c=>c.peer===d.chatId);
        if(!chat){
            chat={id:d.chatId,type:'direct',peer:d.chatId,messages:[]};
            blackChats.push(chat);
        }
        chat.messages.push(d.message);
        if(bcSelectedChat===chat.id||bcSelectedChat===chat.peer)renderBCConversation();
    }
    if(d.action==='groupCreated'){
        if(!groups.find(g=>g.id===d.group.id))groups.push(d.group);
    }
    if(d.action==='groupNewMessage'){
        const grp=groups.find(g=>g.id===d.groupId);
        if(grp){grp.messages.push(d.message);}
    }
    if(d.action==='bcGroupCreated'){
        if(!blackChats.find(c=>c.id===d.group.id))blackChats.push({id:d.group.id,type:'group',name:d.group.name,members:d.group.members,messages:[]});
    }
});

/* ==================== X (TWITTER CLONE) ==================== */
function renderXApp(){
    appTitle.textContent='X';
    let html=`<div class="x-new-post" onclick="showXPost()"><span style="font-size:18px">✏️</span> What's happening?</div><div class="x-tweet-list" id="xTweetList"></div>`;
    appContent.innerHTML=html;
    fetch(`https://${GetParentResourceName()}/xGetTweets`,{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'});
    const list=document.getElementById('xTweetList');if(!list)return;
    if(!xTweets||xTweets.length===0){list.innerHTML='<div style="text-align:center;padding:40px;color:rgba(255,255,255,0.2);font-size:13px">No tweets yet</div>';return;}
    xTweets.forEach(t=>{
        const d=document.createElement('div');d.className='x-tweet';
        d.innerHTML=`<div class="x-tweet-hd"><div class="x-tweet-av">${(t.name||'?').charAt(0).toUpperCase()}</div><div class="x-tweet-nm">${t.name||'Unknown'}</div><div class="x-tweet-tm">${t.created_at?formatMsgTime(t.created_at):''}</div></div><div class="x-tweet-cnt">${t.content||''}</div><div class="x-tweet-acts"><span class="x-tweet-act" onclick="xLikeTweet(${t.id})">♥ ${t.likes||0}</span></div>`;
        list.appendChild(d);
    });
}
function showXPost(){
    appContent.innerHTML=`<div style="padding:8px 0"><textarea class="x-textarea" id="xPostInput" placeholder="What's happening?" maxlength="280"></textarea><div style="display:flex;justify-content:space-between;align-items:center;margin-top:8px"><span style="color:rgba(255,255,255,0.3);font-size:11px" id="xCharCount">0/280</span><button class="x-post-btn" onclick="postXTweet()">Post</button></div></div>`;
    document.getElementById('xPostInput').addEventListener('input',function(){document.getElementById('xCharCount').textContent=this.value.length+'/280';});
}
function postXTweet(){
    const inp=document.getElementById('xPostInput');
    if(inp&&inp.value.trim()){fetch(`https://${GetParentResourceName()}/xPostTweet`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({content:inp.value})});inp.value='';setTimeout(()=>renderXApp(),500);}
}
function xLikeTweet(id){fetch(`https://${GetParentResourceName()}/xLikeTweet`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({tweetId:id})});}

/* ==================== TIKTOK ==================== */
function renderTikTokApp(){
    appTitle.textContent='TikTok';
    fetch(`https://${GetParentResourceName()}/tiktokGetFeed`,{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'});
    let html=`<div class="tiktok-upload-btn" onclick="showTikTokUpload()">📤 Upload</div><div class="tiktok-feed" id="tiktokFeed"></div>`;
    appContent.innerHTML=html;
    const feed=document.getElementById('tiktokFeed');if(!feed)return;
    if(!tiktokVideos||tiktokVideos.length===0){feed.innerHTML='<div style="text-align:center;padding:40px;color:rgba(255,255,255,0.2);font-size:13px">No videos yet</div>';return;}
    tiktokVideos.forEach(v=>{
        const d=document.createElement('div');d.className='tiktok-video';
        let inner=`<div class="tiktok-video-hd"><div class="tiktok-video-av">${(v.name||'?').charAt(0).toUpperCase()}</div><div class="tiktok-video-us">${v.name||'Unknown'}</div></div>`;
        if(v.video_data)inner+=`<div class="tiktok-video-media"><img src="${v.video_data}" class="tiktok-img"/></div>`;
        if(v.description)inner+=`<div class="tiktok-video-desc">${v.description}</div>`;
        inner+=`<div class="tiktok-video-acts"><span class="tiktok-act" onclick="tiktokLike(${v.id})">♥ ${v.likes||0}</span></div>`;
        d.innerHTML=inner;feed.appendChild(d);
    });
}
function showTikTokUpload(){
    const inp=document.createElement('input');inp.type='file';inp.accept='image/*';
    inp.onchange=function(e){const f=e.target.files[0];if(!f)return;const r=new FileReader();r.onload=function(ev){const desc=prompt('Description (optional):')||'';fetch(`https://${GetParentResourceName()}/tiktokUpload`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({videoData:ev.target.result,description:desc})});Wrappers.Notify('Uploaded!','success');};r.readAsDataURL(f);};
    inp.click();
}
function tiktokLike(id){fetch(`https://${GetParentResourceName()}/tiktokLike`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({videoId:id})});}

/* ==================== UBER EATS ==================== */
let ueTab='restaurants';
function renderUberEatsApp(){
    appTitle.textContent='Uber Eats';
    fetch(`https://${GetParentResourceName()}/ubereatsGetRestaurants`,{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'});
    fetch(`https://${GetParentResourceName()}/ubereatsGetOrders`,{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'});
    let html=`<div class="ue-tabs"><div class="ue-tab ${ueTab==='restaurants'?'active':''}" onclick="switchUETab('restaurants')">Restaurants</div><div class="ue-tab ${ueTab==='orders'?'active':''}" onclick="switchUETab('orders')">Orders</div></div><div id="ueContent"></div>`;
    appContent.innerHTML=html;
    if(ueTab==='restaurants')renderUERestaurants();else renderUEOrders();
}
function switchUETab(tab){ueTab=tab;renderUberEatsApp();}
function renderUERestaurants(){
    const el=document.getElementById('ueContent');if(!el)return;
    if(!ubereatsRestaurants||ubereatsRestaurants.length===0){el.innerHTML='<div style="text-align:center;padding:40px;color:rgba(255,255,255,0.2);font-size:13px">No restaurants available</div>';return;}
    let html='';
    ubereatsRestaurants.forEach(r=>{html+=`<div class="ue-restaurant" onclick="showUEMenu(${r.id})"><div class="ue-rest-name">${r.name||'Restaurant'}</div><div class="ue-rest-desc">${r.description||''}</div><div class="ue-rest-info">⏱ ${r.delivery_time||'30-45'} min</div></div>`;});
    el.innerHTML=html;
}
function renderUEOrders(){
    const el=document.getElementById('ueContent');if(!el)return;
    if(!ubereatsOrders||ubereatsOrders.length===0){el.innerHTML='<div style="text-align:center;padding:40px;color:rgba(255,255,255,0.2);font-size:13px">No orders yet</div>';return;}
    let html='';
    ubereatsOrders.forEach(o=>{
        const items=typeof o.items==='string'?JSON.parse(o.items):(o.items||[]);
        const itemsList=items.map(i=>i.name+' x'+(i.qty||1)).join(', ');
        html+=`<div class="ue-order"><div class="ue-order-status ${o.status}">${o.status||'pending'}</div><div class="ue-order-items">${itemsList}</div><div class="ue-order-total">$${(o.total||0).toFixed(2)}</div></div>`;
    });
    el.innerHTML=html;
}
function showUEMenu(restId){
    const rest=ubereatsRestaurants.find(r=>r.id===restId);if(!rest)return;
    const menu=rest.menu||[];let html=`<div class="ue-back" onclick="switchUETab('restaurants')">← ${rest.name}</div>`;
    if(menu.length===0)html+='<div style="text-align:center;padding:40px;color:rgba(255,255,255,0.2);font-size:13px">Menu coming soon</div>';
    else menu.forEach(item=>{html+=`<div class="ue-menu-item"><div class="ue-menu-info"><div class="ue-menu-name">${item.item_name||'Item'}</div><div class="ue-menu-price">$${(item.price||0).toFixed(2)}</div></div><button class="ue-order-btn" onclick="addToCart(${restId},'${item.item_name}',${item.price||0})">+</button></div>`;});
    if(ueCart.length>0)html+=`<button class="taxi-accept-btn" onclick="placeUberEatsOrder(${restId})" style="margin-top:12px">Place Order (${ueCart.length} items)</button>`;
    const el=document.getElementById('ueContent');if(el)el.innerHTML=html;
}
function addToCart(restId,name,price){ueCart.push({restId,name,price,qty:1});Wrappers.Notify('Added: '+name,'success');showUEMenu(restId);}
function placeUberEatsOrder(restId){
    if(ueCart.length===0){Wrappers.Notify('Cart empty','error');return;}
    const items=ueCart.map(i=>({name:i.name,qty:i.qty}));
    fetch(`https://${GetParentResourceName()}/ubereatsPlaceOrder`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({restaurantId:restId,items})});
    ueCart=[];Wrappers.Notify('Order placed!','success');switchUETab('orders');
}

/* ==================== BANKING ==================== */
function renderBankingApp(){
    appTitle.textContent='Banking';
    fetch(`https://${GetParentResourceName()}/bankingGetData`,{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'});
    let html=`<div class="bank-balance-card"><div class="bank-balance-label">Available Balance</div><div class="bank-balance-amount">$${(bankBalance||0).toLocaleString()}</div></div>
    <div class="bank-section"><div class="bank-section-title">Transfer</div><input class="msg-input" id="bankTarget" placeholder="Phone number" style="margin-bottom:8px"/><input class="msg-input" id="bankAmount" placeholder="Amount" type="number" style="margin-bottom:8px"/><button class="taxi-accept-btn" onclick="bankTransfer()">Send Money</button></div>
    <div class="bank-section"><div class="bank-section-title">Recent Transactions</div><div id="bankTransactions"></div></div>`;
    appContent.innerHTML=html;
    renderBankTransactions();
}
function renderBankTransactions(){
    const el=document.getElementById('bankTransactions');if(!el)return;
    if(!bankTransactions||bankTransactions.length===0){el.innerHTML='<div style="text-align:center;padding:20px;color:rgba(255,255,255,0.2);font-size:13px">No transactions</div>';return;}
    let html='';
    bankTransactions.forEach(t=>{
        const sent=t.type==='sent';
        html+=`<div class="bank-tx"><div class="bank-tx-icon">${sent?'⬆':'⬇'}</div><div class="bank-tx-info"><div class="bank-tx-target">${t.target||'Unknown'}</div><div class="bank-tx-date">${t.created_at?formatMsgTime(t.created_at):''}</div></div><div class="bank-tx-amount ${sent?'sent':'received'}">${sent?'-':'+'}$${(t.amount||0).toLocaleString()}</div></div>`;
    });
    el.innerHTML=html;
}
function bankTransfer(){
    const target=document.getElementById('bankTarget')?.value;const amount=document.getElementById('bankAmount')?.value;
    if(!target||!amount||parseFloat(amount)<=0){Wrappers.Notify('Invalid input','error');return;}
    fetch(`https://${GetParentResourceName()}/bankingTransfer`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({target,amount:parseFloat(amount)})});
    Wrappers.Notify('Transfer initiated','info');
}

/* ==================== WEATHER & TIME MACHINE ==================== */
let wIcons={'EXTRASUNNY':'☀️','CLEAR':'🌤','CLOUDS':'☁️','SMOG':'🌫','FOGGY':'🌫','OVERCAST':'☁️','RAIN':'🌧','THUNDER':'⛈','CLEARING':'🌤','NEUTRAL':'🌥','SNOW':'❄️','BLIZZARD':'🌨','SNOWLIGHT':'🌨','XMAS':'🎄','HALLOWEEN':'🎃'};
let wLabels={'EXTRASUNNY':'Extra Sunny','CLEAR':'Clear','CLOUDS':'Clouds','SMOG':'Smog','FOGGY':'Foggy','OVERCAST':'Overcast','RAIN':'Rain','THUNDER':'Thunder','CLEARING':'Clearing','NEUTRAL':'Neutral','SNOW':'Snow','BLIZZARD':'Blizzard','SNOWLIGHT':'Snow Light','XMAS':'Christmas','HALLOWEEN':'Halloween'};
let wWeights={'EXTRASUNNY':20,'CLEAR':25,'CLOUDS':15,'SMOG':5,'FOGGY':5,'OVERCAST':10,'RAIN':8,'THUNDER':3,'CLEARING':5,'NEUTRAL':2,'SNOW':1,'BLIZZARD':0.5,'SNOWLIGHT':0.5};
let fcastCache=[];
let wTimeSlider=0;
function renderWeatherApp(){
    appTitle.textContent='Weather';
    fetch(`https://${GetParentResourceName()}/weatherGetData`,{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'});
    let html=`<div class="w-current" id="wCurrent"><div style="text-align:center;padding:40px;color:rgba(255,255,255,0.2)">Loading...</div></div><div class="w-forecast" id="wForecast"></div><div class="w-tmachine"><div class="w-tm-title">🕐 Time Machine</div><div class="w-tm-slider-wrap"><input type="range" class="w-tm-slider" id="wTmSlider" min="0" max="24" value="0" step="1" oninput="updateTMachine(this.value)"/></div><div class="w-tm-info" id="wTmInfo">Slide to see future weather</div></div>`;
    appContent.innerHTML=html;
}
function applyWeatherData(d){
    document.getElementById('wCurrent').innerHTML=`<div class="w-current-icon">${wIcons[d.weather]||'🌤'}</div><div class="w-current-type">${wLabels[d.weather]||d.weather}</div><div class="w-current-time">${String(d.hour).padStart(2,'0')}:${String(d.minute).padStart(2,'0')}</div><div class="w-current-details"><span>🌅 ${String(d.sunrise||6).padStart(2,'0')}:00</span><span>🌇 ${String(d.sunset||20).padStart(2,'0')}:00</span>${d.blackout?'<span class="w-blackout">⚡ BLACKOUT</span>':''}</div>`;
    generateForecast(d.weather);
}
function generateForecast(currentW){
    fcastCache=[];let w=currentW;
    for(let i=1;i<=6;i++){
        const totalW=Object.values(wWeights).reduce((a,b)=>a+b,0);
        let roll=Math.random()*totalW,cum=0,next='CLEAR';
        for(const[wt,wtv]of Object.entries(wWeights)){cum+=wtv;if(roll<=cum){next=wt;break;}}
        fcastCache.push(next);w=next;
    }
    let html='<div class="w-fc-title">6-Hour Forecast</div><div class="w-fc-row">';
    fcastCache.forEach((w,i)=>{html+=`<div class="w-fc-item"><div class="w-fc-icon">${wIcons[w]||'🌤'}</div><div class="w-fc-label">+${i+1}h</div><div class="w-fc-name">${wLabels[w]||w}</div></div>`;});
    html+='</div>';
    document.getElementById('wForecast').innerHTML=html;
    const el=document.getElementById('wTmSlider');
    if(el){el.value=0;wTimeSlider=0;document.getElementById('wTmInfo').textContent='Slide to see future weather';}
}
function updateTMachine(val){
    wTimeSlider=parseInt(val);
    const idx=Math.min(wTimeSlider-1,fcastCache.length-1);
    if(wTimeSlider===0){document.getElementById('wTmInfo').innerHTML='⏸ Current time';return;}
    const fw=fcastCache[idx]||'CLEAR';
    document.getElementById('wTmInfo').innerHTML=`<div style="display:flex;align-items:center;gap:8px"><span style="font-size:28px">${wIcons[fw]||'🌤'}</span><div><div style="font-size:16px;color:#fff;font-weight:600">${wLabels[fw]||fw}</div><div style="font-size:12px;color:rgba(255,255,255,0.4)">In ~${wTimeSlider} hour${wTimeSlider>1?'s':''}</div></div></div>`;
}

/* ==================== GIGS (SERVER JOBS BOARD) ==================== */
let gigs=[];
let gFilter='open';
function renderGigsApp(){
    appTitle.textContent='Gigs';
    fetch(`https://${GetParentResourceName()}/gigsGetList`,{method:'POST',headers:{'Content-Type':'application/json'},body:'{}'});
    let html=`<div class="g-tabs"><div class="g-tab ${gFilter==='open'?'active':''}" onclick="switchGTab('open')">Open</div><div class="g-tab ${gFilter==='mine'?'active':''}" onclick="switchGTab('mine')">Mine</div><div class="g-tab ${gFilter==='history'?'active':''}" onclick="switchGTab('history')">History</div></div><div id="gContent"></div>`;
    appContent.innerHTML=html;
    const btn=document.createElement('div');btn.className='g-post-btn';btn.textContent='➕ Post a Gig';btn.onclick=showGigPostForm;
    appContent.insertBefore(btn,appContent.firstChild);
    renderGigsList();
}
function switchGTab(t){gFilter=t;renderGigsApp();}
function renderGigsList(){
    const el=document.getElementById('gContent');if(!el)return;
    let filtered=[];
    if(gFilter==='open')filtered=gigs.filter(g=>g.status==='open');
    else if(gFilter==='mine')filtered=gigs.filter(g=>g.poster_cid===myCitizenId||g.worker_cid===myCitizenId);
    else filtered=gigs;
    if(!filtered||filtered.length===0){el.innerHTML='<div style="text-align:center;padding:40px;color:rgba(255,255,255,0.2);font-size:13px">No gigs found</div>';return;}
    let html='';
    filtered.forEach(g=>{
        const isPoster=g.poster_cid===myCitizenId;
        html+=`<div class="g-card"><div class="g-card-title">${g.title||'Untitled'}</div><div class="g-card-desc">${g.description||''}</div><div class="g-card-meta"><span class="g-card-reward">$${(g.reward||0).toLocaleString()}</span><span class="g-card-loc">${g.location_label||'No location'}</span></div><div class="g-card-status ${g.status}">${g.status}</div><div class="g-card-actions">`;
        if(g.status==='open'&&!isPoster)html+=`<button class="g-btn accept" onclick="acceptGig(${g.id})">Accept</button>`;
        if(g.status==='assigned'&&g.worker_cid===myCitizenId)html+=`<button class="g-btn complete" onclick="completeGig(${g.id})">Complete</button>`;
        if((g.status==='open'||g.status==='assigned')&&isPoster)html+=`<button class="g-btn cancel" onclick="cancelGig(${g.id})">Cancel</button>`;
        html+=`</div></div>`;
    });
    el.innerHTML=html;
}
function showGigPostForm(){
    appContent.innerHTML=`<div style="padding:8px 0"><input class="msg-input" id="gTitle" placeholder="Gig title" style="margin-bottom:8px"/><textarea class="x-textarea" id="gDesc" placeholder="Description" style="margin-bottom:8px"></textarea><input class="msg-input" id="gReward" placeholder="Reward $" type="number" style="margin-bottom:8px"/><input class="msg-input" id="gLoc" placeholder="Location label (e.g. Legion Square)" style="margin-bottom:12px"/><button class="taxi-accept-btn" onclick="postGig()">Post Gig</button></div>`;
}
function postGig(){
    const t=document.getElementById('gTitle')?.value,d=document.getElementById('gDesc')?.value,r=document.getElementById('gReward')?.value,l=document.getElementById('gLoc')?.value;
    if(!t||!r||parseFloat(r)<=0){Wrappers.Notify('Title and reward required','error');return;}
    fetch(`https://${GetParentResourceName()}/gigsPost`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({title:t,description:d||'',reward:parseFloat(r),location_label:l||''})});
    document.getElementById('gTitle').value='';document.getElementById('gDesc').value='';document.getElementById('gReward').value='';document.getElementById('gLoc').value='';
    setTimeout(()=>renderGigsApp(),500);
}
function acceptGig(id){fetch(`https://${GetParentResourceName()}/gigsAccept`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({gigId:id})});setTimeout(()=>renderGigsApp(),500);}
function completeGig(id){fetch(`https://${GetParentResourceName()}/gigsComplete`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({gigId:id})});setTimeout(()=>renderGigsApp(),500);}
function cancelGig(id){fetch(`https://${GetParentResourceName()}/gigsCancel`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({gigId:id})});setTimeout(()=>renderGigsApp(),500);}

/* ==================== UTILITY ==================== */
function formatTime(s){const m=Math.floor(s/60);const sec=s%60;return m.toString().padStart(2,'0')+':'+sec.toString().padStart(2,'0');}
function formatMsgTime(ts){const d=new Date(ts*1000);const now=new Date();if(d.toDateString()===now.toDateString())return d.getHours().toString().padStart(2,'0')+':'+d.getMinutes().toString().padStart(2,'0');return d.getMonth()+1+'/'+d.getDate();}

document.addEventListener('keydown',function(e){
    if(e.key==='Escape'&&!appView.classList.contains('hidden')){showHome();}
});

/* ==================== 911 EMERGENCY APP ==================== */
const EMERGENCY_TYPES = [
    { id: 'active_shooter', label: 'Active Shooter', icon: 'fas fa-skull', color: '#ff3b30' },
    { id: 'robbery', label: 'Robbery', icon: 'fas fa-mask', color: '#ff9500' },
    { id: 'domestic', label: 'Domestic', icon: 'fas fa-home', color: '#ffcc00' },
    { id: 'traffic_accident', label: 'Traffic Accident', icon: 'fas fa-car-crash', color: '#ff6b35' },
    { id: 'suspicious_person', label: 'Suspicious Person', icon: 'fas fa-user-secret', color: '#5ac8fa' },
    { id: 'medical', label: 'Medical', icon: 'fas fa-heartbeat', color: '#30d158' },
    { id: 'fire', label: 'Fire', icon: 'fas fa-fire', color: '#ff453a' },
    { id: 'assault', label: 'Assault', icon: 'fas fa-fist-raised', color: '#bf5af2' },
];

let selectedEmergencyType = null;
let emergencySent = false;

function renderEmergencyApp() {
    appTitle.textContent = '911';
    emergencySent = false;
    selectedEmergencyType = null;
    let typesHtml = EMERGENCY_TYPES.map(t => `
        <div class="em-type-btn" data-id="${t.id}" style="background:${t.color}22;border-color:${t.color}" onclick="selectEmergencyType('${t.id}')">
            <i class="${t.icon}"></i>
            <span>${t.label}</span>
        </div>
    `).join('');
    appContent.innerHTML = `
        <div class="em-container">
            <div class="em-header">
                <div class="em-badge">EMERGENCY</div>
                <div class="em-subtitle">Select the type of emergency</div>
            </div>
            <div class="em-types-grid">${typesHtml}</div>
            <button class="em-send-btn" id="emSendBtn" disabled onclick="sendEmergency()">
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"/></svg>
                Call 911
            </button>
            <div class="em-confirm" id="emConfirm" style="display:none">
                <div class="em-confirm-icon">✓</div>
                <div class="em-confirm-text">911 Dispatched. Units on the way.</div>
            </div>
        </div>
    `;
}

function selectEmergencyType(id) {
    selectedEmergencyType = id;
    document.querySelectorAll('.em-type-btn').forEach(b => b.classList.toggle('selected', b.dataset.id === id));
    const btn = document.getElementById('emSendBtn');
    if (btn) btn.disabled = false;
}

function sendEmergency() {
    if (!selectedEmergencyType || emergencySent) return;
    emergencySent = true;
    const type = EMERGENCY_TYPES.find(t => t.id === selectedEmergencyType);
    fetch(`https://${GetParentResourceName()}/emergencyCall911`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ type: type.label })
    });
    document.getElementById('emSendBtn').style.display = 'none';
    document.getElementById('emConfirm').style.display = 'flex';
}

/* Expose Wrappers for phone usage from Lua */
window.Wrappers=window.Wrappers||{};
if(!window.Wrappers.ContextMenu)window.Wrappers.ContextMenu=function(params){
    const container=document.createElement('div');
    container.style.cssText='position:fixed;top:0;left:0;right:0;bottom:0;z-index:9999;display:flex;align-items:flex-end;justify-content:center;background:rgba(0,0,0,0.5)';
    const menu=document.createElement('div');
    menu.style.cssText='background:rgba(30,30,50,0.95);backdrop-filter:blur(20px);border-radius:16px 16px 0 0;padding:16px;width:100%;max-width:393px;margin-bottom:60px';
    let html='';
    if(params.title)html+=`<div style="text-align:center;color:#fff;font-weight:600;font-size:15px;padding:8px 0 12px;border-bottom:1px solid rgba(255,255,255,0.05);margin-bottom:8px">${params.title}</div>`;
    (params.menuItems||[]).forEach(item=>{
        html+=`<div style="padding:14px 12px;color:#fff;font-size:14px;cursor:pointer;border-bottom:1px solid rgba(255,255,255,0.04);display:flex;justify-content:space-between" onclick="this.closest('[data-context]').remove();${item.onSelect?'('+item.onSelect.toString()+')()':''}">
            <span>${item.title||''}</span>
            ${item.description?`<span style="color:rgba(255,255,255,0.3);font-size:12px">${item.description}</span>`:''}
        </div>`;
    });
    menu.innerHTML=html;container.setAttribute('data-context','');container.appendChild(menu);
    container.addEventListener('click',function(e){if(e.target===container)container.remove();});
    document.body.appendChild(container);
};

if(!window.Wrappers.Notify)window.Wrappers.Notify=function(msg,type){
    const el=document.createElement('div');
    el.style.cssText=`position:fixed;top:60px;left:50%;transform:translateX(-50%);z-index:99999;padding:10px 20px;border-radius:12px;font-size:13px;font-family:'Inter',sans-serif;color:#fff;background:${type==='error'?'#ff5f56':type==='success'?'#27c93f':'rgba(0,0,0,0.8)'};backdrop-filter:blur(10px);max-width:360px;text-align:center;transition:opacity 0.3s`;
    el.textContent=msg;
    document.body.appendChild(el);
    setTimeout(()=>{el.style.opacity='0';setTimeout(()=>el.remove(),300);},2000);
};
