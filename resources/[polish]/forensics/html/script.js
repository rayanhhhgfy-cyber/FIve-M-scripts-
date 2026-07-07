let evidenceData = [];
let selectedEvidence = null;
let isAnalyzing = false;

window.addEventListener('message', function(event) {
    const msg = event.data;
    if (msg.action === 'openTerminal') {
        evidenceData = msg.data.evidence || [];
        selectedEvidence = null;
        isAnalyzing = false;
        document.getElementById('terminal').style.display = 'flex';
        document.getElementById('overlay').style.display = 'block';
        renderEvidenceList();
        renderAnalysisPanel();
    }
    if (msg.action === 'analysisResult') {
        isAnalyzing = false;
        renderAnalysisPanel(msg.data);
    }
});

document.getElementById('closeBtn').addEventListener('click', close);
document.getElementById('overlay').addEventListener('click', close);
document.addEventListener('keydown', function(e) { if (e.key === 'Escape') close(); });

function close() {
    document.getElementById('terminal').style.display = 'none';
    document.getElementById('overlay').style.display = 'none';
    fetch('https://' + GetParentResourceName() + '/closeTerminal', { method: 'POST', body: '{}' });
}

function renderEvidenceList() {
    const container = document.getElementById('evidence-items');
    container.innerHTML = '';

    if (evidenceData.length === 0) {
        container.innerHTML = '<div class="placeholder" style="padding: 20px;">No evidence in inventory</div>';
        return;
    }

    evidenceData.forEach(function(ev) {
        const card = document.createElement('div');
        card.className = 'evidence-card' + (selectedEvidence && selectedEvidence.id === ev.id ? ' active' : '');
        card.innerHTML =
            '<div class="evidence-type type-' + ev.type + '">' +
            (ev.type === 'fingerprint' ? '<i class="fas fa-fingerprint"></i>' :
             ev.type === 'casing' ? '<i class="fas fa-bullseye"></i>' :
             '<i class="fas fa-dna"></i>') +
            ' ' + ev.type + '</div>' +
            '<div class="evidence-id">' + ev.id + '</div>' +
            '<div class="evidence-time">' + ev.time + '</div>' +
            '<div class="evidence-by">' + ev.collectedBy + '</div>';
        card.addEventListener('click', function() {
            selectedEvidence = ev;
            renderEvidenceList();
            renderAnalysisPanel();
        });
        container.appendChild(card);
    });
}

function renderAnalysisPanel(result) {
    const container = document.getElementById('analysis-content');
    container.innerHTML = '';

    if (result) {
        let html = '<div class="result-card">';
        html += '<div class="result-header"><i class="fas fa-flask"></i> Analysis Complete — ' + result.evidenceId + '</div>';
        html += '<div class="result-field"><span class="label">Type:</span> <span class="value">' + result.evidenceType + '</span></div>';
        html += '<div class="result-field"><span class="label">Collected By:</span> <span class="value">' + (result.collectedBy || 'Unknown') + '</span></div>';
        html += '<div class="result-field"><span class="label">Collection Time:</span> <span class="value">' + (result.collectedAt || 'Unknown') + '</span></div>';
        html += '<div class="result-field"><span class="label">Database Match:</span> <span class="value"><span class="match-badge match-' + result.match + '">' + (result.match ? 'MATCH FOUND' : 'NO MATCH') + '</span></span></div>';
        if (result.match) {
            html += '<div class="result-field"><span class="label">Match Type:</span> <span class="value">' + (result.matchType || 'N/A') + '</span></div>';
            html += '<div class="result-field"><span class="label">Matched To:</span> <span class="value">' + (result.matchName || 'Unknown') + '</span></div>';
        }
        html += '<div class="result-field"><span class="label">Details:</span> <span class="value">' + (result.details || 'None') + '</span></div>';
        html += '</div>';
        container.innerHTML = html;
        return;
    }

    if (!selectedEvidence) {
        container.innerHTML = '<div class="placeholder">Select an evidence item from the list to begin analysis</div>';
        return;
    }

    let html = '<div class="result-card">';
    html += '<div class="result-header"><i class="fas fa-box"></i> Selected Evidence</div>';
    html += '<div class="result-field"><span class="label">ID:</span> <span class="value">' + selectedEvidence.id + '</span></div>';
    html += '<div class="result-field"><span class="label">Type:</span> <span class="value">' + selectedEvidence.type + '</span></div>';
    html += '<div class="result-field"><span class="label">Collected:</span> <span class="value">' + selectedEvidence.time + '</span></div>';
    html += '<div class="result-field"><span class="label">By:</span> <span class="value">' + selectedEvidence.collectedBy + '</span></div>';
    html += '</div>';
    html += '<button class="analyze-btn" id="analyzeBtn"' + (isAnalyzing ? ' disabled' : '') + '>' +
            (isAnalyzing ? '<i class="fas fa-spinner fa-spin"></i> Analyzing...' : '<i class="fas fa-microscope"></i> Run Analysis') +
            '</button>';
    container.innerHTML = html;

    document.getElementById('analyzeBtn').addEventListener('click', function() {
        if (isAnalyzing) return;
        isAnalyzing = true;
        this.disabled = true;
        this.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Analyzing...';
        fetch('https://' + GetParentResourceName() + '/analyzeEvidence', {
            method: 'POST',
            body: JSON.stringify({ evidenceId: selectedEvidence.id })
        });
    });
}
