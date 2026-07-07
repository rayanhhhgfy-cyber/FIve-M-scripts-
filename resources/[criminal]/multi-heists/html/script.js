const cells = document.querySelectorAll('.hack-cell');
const statusDiv = document.getElementById('hack-status');
const patternDisplay = document.getElementById('pattern-display');
const progressFill = document.getElementById('progress-fill');

let heistId = null;
let pattern = [];
let playerPattern = [];
let patternIndex = 0;
let sequenceLength = 4;
let isShowingPattern = false;
let isPlayerTurn = false;
let round = 0;
const maxRounds = 4;

function init(data) {
    heistId = data.heistId;
    const difficulty = data.difficulty || 0.5;
    sequenceLength = Math.floor(4 + (1 - difficulty) * 4);
    round = 0;
    nextRound();
}

function nextRound() {
    round++;
    playerPattern = [];
    patternIndex = 0;
    pattern = [];
    progressFill.style.width = ((round - 1) / maxRounds * 100) + '%';

    if (round > maxRounds) {
        succeed();
        return;
    }

    for (let i = 0; i < sequenceLength; i++) {
        pattern.push(Math.floor(Math.random() * 4));
    }

    statusDiv.textContent = 'Round ' + round + '/' + maxRounds + ' — Watch the pattern...';
    showPattern();
}

function showPattern() {
    isShowingPattern = true;
    isPlayerTurn = false;
    let i = 0;
    patternDisplay.innerHTML = '';
    for (let p = 0; p < pattern.length; p++) {
        const dot = document.createElement('div');
        dot.className = 'pattern-dot';
        dot.dataset.index = p;
        patternDisplay.appendChild(dot);
    }

    const interval = setInterval(function() {
        // Clear all
        cells.forEach(function(c) { c.className = 'hack-cell'; });

        if (i >= pattern.length) {
            clearInterval(interval);
            setTimeout(function() {
                isShowingPattern = false;
                isPlayerTurn = true;
                statusDiv.textContent = 'Your turn — Repeat the pattern!';
                // Clear pattern dots
                document.querySelectorAll('.pattern-dot').forEach(function(d) {
                    d.classList.remove('active');
                });
            }, 500);
            return;
        }

        const idx = pattern[i];
        cells[idx].className = 'hack-cell lit-' + idx;

        // Update pattern dots
        document.querySelectorAll('.pattern-dot').forEach(function(d, di) {
            if (di <= i) d.classList.add('active');
        });

        i++;
    }, 600);
}

cells.forEach(function(cell) {
    cell.addEventListener('click', function() {
        if (!isPlayerTurn || isShowingPattern) return;
        const idx = parseInt(this.dataset.index);

        cell.className = 'hack-cell lit-' + idx;
        setTimeout(function() { cell.className = 'hack-cell'; }, 200);

        const expected = pattern[playerPattern.length];
        if (idx === expected) {
            playerPattern.push(idx);
            statusDiv.textContent = 'Correct! ' + playerPattern.length + '/' + pattern.length;

            if (playerPattern.length >= pattern.length) {
                isPlayerTurn = false;
                statusDiv.textContent = 'Pattern matched!';
                setTimeout(nextRound, 600);
            }
        } else {
            isPlayerTurn = false;
            cell.className = 'hack-cell wrong';
            setTimeout(function() {
                cell.className = 'hack-cell';
                fail();
            }, 400);
        }
    });
});

function succeed() {
    progressFill.style.width = '100%';
    statusDiv.textContent = 'BYPASS COMPLETE';
    statusDiv.style.color = '#4caf50';
    setTimeout(function() {
        fetch('https://' + GetParentResourceName() + '/hackResult', {
            method: 'POST',
            body: JSON.stringify({ success: true, heistId: heistId })
        });
    }, 800);
}

function fail() {
    statusDiv.textContent = 'BYPASS FAILED';
    statusDiv.style.color = '#f44336';
    setTimeout(function() {
        fetch('https://' + GetParentResourceName() + '/hackResult', {
            method: 'POST',
            body: JSON.stringify({ success: false, heistId: heistId })
        });
    }, 800);
}

document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        if (isShowingPattern || isPlayerTurn) {
            isShowingPattern = false;
            isPlayerTurn = false;
            fetch('https://' + GetParentResourceName() + '/cancelHack', { method: 'POST', body: '{}' });
        }
    }
});

window.addEventListener('message', function(event) {
    const msg = event.data;
    if (msg.action === 'startHack') {
        document.getElementById('hack-container').style.display = 'block';
        init(msg.data);
    }
    if (msg.action === 'closeHack') {
        document.getElementById('hack-container').style.display = 'none';
    }
});
