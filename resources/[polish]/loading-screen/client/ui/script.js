const tips = [
    'Use /report to contact staff if you need assistance.',
    'Press M to open the map and navigate the city.',
    'Check your inventory with the Z key.',
    'Use /ooc for out-of-character chat with other players.',
    'Visit the City Hall to get your ID card and bank card.',
    'Police vehicles can be accessed at any PD garage.',
    'CID operatives have access to undercover vehicles with identity switching.',
    'Use your phone (F1) to call, text, and use apps.',
    'The premium dealership offers luxury, sports, and normal vehicles.',
    'ATMs require a bank card — get yours at City Hall.',
    'Payroll is processed every 25 in-game days.',
    'Use F5 to save and load outfits anywhere in the city.',
    'Panic button alerts all available units to your location.',
    'Dispatch can track officer GPS in real time.',
    'Covert entry kits allow silent breach operations.',
    'Surveillance bugs stream audio and video to CID HQ.',
    'Operations center coordinates team movements on a live map.',
    'BOLO alerts are shared across all law enforcement channels.',
    'Vehicle lock (L key) only works on owned vehicles.',
    'Park responsibly — impound fees apply for illegal parking.',
];

let progress = 0;
let tipIndex = 0;
const progressBar = document.getElementById('progress-bar');
const progressText = document.getElementById('progress-text');
const tipText = document.getElementById('tip-text');
const statusText = document.getElementById('status-text');

const statusMessages = [
    'Loading city assets...',
    'Spawning vehicles...',
    'Initializing systems...',
    'Preparing world...',
    'Loading player data...',
    'Almost there...',
    'Finalizing...',
];

function shuffleArray(arr) {
    for (let i = arr.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [arr[i], arr[j]] = [arr[j], arr[i]];
    }
    return arr;
}

const shuffledTips = shuffleArray([...tips]);

function rotateTip() {
    tipText.style.opacity = '0';
    setTimeout(() => {
        tipIndex = (tipIndex + 1) % shuffledTips.length;
        tipText.textContent = shuffledTips[tipIndex];
        tipText.style.opacity = '1';
    }, 600);
}

function updateProgress() {
    if (progress >= 100) {
        progress = 100;
        progressBar.style.width = '100%';
        progressText.textContent = '100%';
        statusText.textContent = 'Connected';
        fetch('https://' + GetParentResourceName() + '/loadingComplete', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({}),
        });
        return;
    }
    const increment = Math.floor(Math.random() * 4) + 1;
    progress = Math.min(100, progress + increment);
    progressBar.style.width = progress + '%';
    progressText.textContent = progress + '%';
    const statusIndex = Math.floor((progress / 100) * statusMessages.length);
    statusText.textContent = statusMessages[Math.min(statusIndex, statusMessages.length - 1)];
}

function createParticles() {
    const container = document.getElementById('particles');
    for (let i = 0; i < 30; i++) {
        const particle = document.createElement('div');
        particle.style.cssText = `
            position: absolute;
            width: ${Math.random() * 3 + 1}px;
            height: ${Math.random() * 3 + 1}px;
            background: rgba(43, 125, 233, ${Math.random() * 0.3 + 0.1});
            border-radius: 50%;
            top: ${Math.random() * 100}%;
            left: ${Math.random() * 100}%;
            animation: float ${Math.random() * 10 + 10}s linear infinite;
            animation-delay: ${Math.random() * 5}s;
            opacity: 0;
        `;
        container.appendChild(particle);
    }
}

const style = document.createElement('style');
style.textContent = `
    @keyframes float {
        0% { transform: translateY(0) translateX(0); opacity: 0; }
        10% { opacity: 1; }
        90% { opacity: 1; }
        100% { transform: translateY(-100vh) translateX(${Math.random() * 100 - 50}px); opacity: 0; }
    }
`;
document.head.appendChild(style);

function startLoading() {
    tipText.textContent = shuffledTips[0];
    setInterval(rotateTip, 6000);
    setInterval(updateProgress, 700);
}

window.addEventListener('message', function(event) {
    const data = event.data;
    if (data.action === 'show') {
        document.body.style.display = 'flex';
        progress = 0;
        progressBar.style.width = '0%';
        progressText.textContent = '0%';
        statusText.textContent = 'Initializing...';
        createParticles();
        startLoading();
    } else if (data.action === 'hide') {
        document.body.style.display = 'none';
    }
});

document.body.style.display = 'none';
