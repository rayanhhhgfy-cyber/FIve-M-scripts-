const canvas = document.getElementById('lockpick-canvas');
const ctx = canvas.getContext('2d');
const roundDisplay = document.getElementById('round-display');
const failDisplay = document.getElementById('fail-display');
const statusDiv = document.getElementById('lockpick-status');

const cx = 140, cy = 140, radius = 120;

let sweetSpotSize = 0.30;
let needleSpeed = 0.75;
let totalRounds = 4;
let maxFails = 3;

let currentRound = 0;
let currentFails = 0;
let needleAngle = 0;
let sweetSpotStart = 0;
let animationId = null;
let isRunning = false;
let netId = null;
let roundComplete = false;

function init(data) {
    netId = data.netId || 0;
    sweetSpotSize = data.sweetSpotSize || 0.30;
    needleSpeed = data.needleSpeed || 0.75;
    totalRounds = data.rounds || 4;
    maxFails = data.maxFails || 3;
    currentRound = 0;
    currentFails = 0;
    needleAngle = Math.random() * Math.PI * 2;
    roundComplete = false;
    statusDiv.textContent = '';
    statusDiv.className = '';
    nextRound();
}

function nextRound() {
    currentRound++;
    roundComplete = false;
    sweetSpotStart = Math.random() * Math.PI * 2;
    roundDisplay.textContent = 'Round ' + currentRound + ' / ' + totalRounds;
    failDisplay.textContent = 'Fails: ' + currentFails + ' / ' + maxFails;

    if (animationId) cancelAnimationFrame(animationId);
    isRunning = true;
    animate();
}

function animate() {
    if (!isRunning) return;

    needleAngle += needleSpeed * 0.02;
    if (needleAngle > Math.PI * 2) needleAngle -= Math.PI * 2;

    draw();
    animationId = requestAnimationFrame(animate);
}

function draw() {
    ctx.clearRect(0, 0, 280, 280);

    // Outer ring
    ctx.beginPath();
    ctx.arc(cx, cy, radius, 0, Math.PI * 2);
    ctx.strokeStyle = '#1a2d3d';
    ctx.lineWidth = 3;
    ctx.stroke();

    // Tick marks
    for (let i = 0; i < 36; i++) {
        const angle = (i / 36) * Math.PI * 2;
        const inner = i % 3 === 0 ? radius - 15 : radius - 8;
        ctx.beginPath();
        ctx.moveTo(cx + Math.cos(angle) * inner, cy + Math.sin(angle) * inner);
        ctx.lineTo(cx + Math.cos(angle) * radius, cy + Math.sin(angle) * radius);
        ctx.strokeStyle = i % 3 === 0 ? '#3a5f7a' : '#1a2d3d';
        ctx.lineWidth = i % 3 === 0 ? 2 : 1;
        ctx.stroke();
    }

    // Sweet spot arc
    const spotEnd = sweetSpotStart + sweetSpotSize;
    ctx.beginPath();
    ctx.arc(cx, cy, radius - 4, sweetSpotStart, spotEnd);
    ctx.strokeStyle = '#ffd700';
    ctx.lineWidth = 8;
    ctx.lineCap = 'round';
    ctx.shadowColor = 'rgba(255, 215, 0, 0.4)';
    ctx.shadowBlur = 12;
    ctx.stroke();
    ctx.shadowBlur = 0;

    // Sweet spot end glow
    ctx.beginPath();
    ctx.arc(
        cx + Math.cos(spotEnd) * (radius - 4),
        cy + Math.sin(spotEnd) * (radius - 4),
        4, 0, Math.PI * 2
    );
    ctx.fillStyle = 'rgba(255, 215, 0, 0.3)';
    ctx.fill();

    // Sweet spot label
    ctx.fillStyle = '#ffd700';
    ctx.font = '10px sans-serif';
    ctx.textAlign = 'center';
    const labelAngle = sweetSpotStart + sweetSpotSize / 2;
    ctx.fillText('CLICK HERE', cx + Math.cos(labelAngle) * (radius - 20), cy + Math.sin(labelAngle) * (radius - 20) + 3);

    // Needle
    const needleLen = radius - 10;
    ctx.beginPath();
    ctx.moveTo(cx, cy);
    ctx.lineTo(cx + Math.cos(needleAngle) * needleLen, cy + Math.sin(needleAngle) * needleLen);
    ctx.strokeStyle = '#00bcd4';
    ctx.lineWidth = 3;
    ctx.lineCap = 'round';
    ctx.shadowColor = 'rgba(0, 188, 212, 0.5)';
    ctx.shadowBlur = 8;
    ctx.stroke();
    ctx.shadowBlur = 0;

    // Center dot
    ctx.beginPath();
    ctx.arc(cx, cy, 6, 0, Math.PI * 2);
    ctx.fillStyle = '#00bcd4';
    ctx.shadowColor = 'rgba(0, 188, 212, 0.6)';
    ctx.shadowBlur = 12;
    ctx.fill();
    ctx.shadowBlur = 0;

    // Center inner dot
    ctx.beginPath();
    ctx.arc(cx, cy, 3, 0, Math.PI * 2);
    ctx.fillStyle = '#0d1520';
    ctx.fill();
}

function isNeedleInSweetSpot() {
    let angle = needleAngle % (Math.PI * 2);
    if (angle < 0) angle += Math.PI * 2;
    let start = sweetSpotStart % (Math.PI * 2);
    if (start < 0) start += Math.PI * 2;
    let end = start + sweetSpotSize;

    if (end > Math.PI * 2) {
        return angle >= start || angle <= (end - Math.PI * 2);
    } else {
        return angle >= start && angle <= end;
    }
}

canvas.addEventListener('click', function() {
    if (!isRunning || roundComplete) return;

    if (isNeedleInSweetSpot()) {
        isRunning = false;
        if (animationId) cancelAnimationFrame(animationId);
        roundComplete = true;

        statusDiv.textContent = '✓ Success!';
        statusDiv.className = 'success';

        // Flash green
        ctx.shadowColor = 'rgba(76, 175, 80, 0.3)';
        ctx.shadowBlur = 20;

        setTimeout(function() {
            if (currentRound >= totalRounds) {
                statusDiv.textContent = '✓ Vehicle started!';
                fetch('https://' + GetParentResourceName() + '/lockpickResult', {
                    method: 'POST',
                    body: JSON.stringify({ success: true, netId: netId })
                });
                setTimeout(function() {
                    fetch('https://' + GetParentResourceName() + '/closeLockpick', { method: 'POST', body: '{}' });
                }, 800);
            } else {
                nextRound();
            }
        }, 400);
    } else {
        currentFails++;
        failDisplay.textContent = 'Fails: ' + currentFails + ' / ' + maxFails;
        statusDiv.textContent = '✗ Missed!';
        statusDiv.className = 'fail';

        // Flash red
        ctx.shadowColor = 'rgba(244, 67, 54, 0.3)';
        ctx.shadowBlur = 20;

        if (currentFails >= maxFails) {
            isRunning = false;
            if (animationId) cancelAnimationFrame(animationId);
            setTimeout(function() {
                fetch('https://' + GetParentResourceName() + '/lockpickResult', {
                    method: 'POST',
                    body: JSON.stringify({ success: false, netId: netId })
                });
            }, 600);
        }
    }
});

document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape' || e.key === 'Backspace') {
        if (isRunning || currentRound > 0) {
            isRunning = false;
            if (animationId) cancelAnimationFrame(animationId);
            fetch('https://' + GetParentResourceName() + '/cancelLockpick', { method: 'POST', body: '{}' });
        }
    }
});

window.addEventListener('message', function(event) {
    const msg = event.data;
    if (msg.action === 'startLockpick') {
        netId = msg.data.netId || 0;
        document.getElementById('lockpick-container').style.display = 'block';
        init(msg.data);
    }
    if (msg.action === 'closeLockpick') {
        document.getElementById('lockpick-container').style.display = 'none';
        isRunning = false;
        if (animationId) cancelAnimationFrame(animationId);
    }
});
