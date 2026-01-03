let targets = [];
let permissions = [];

function loadModule(moduleName) {
    // Deactivate all modules
    document.querySelectorAll('.module').forEach(m => m.classList.remove('active'));
    document.querySelectorAll('.display-module').forEach(d => d.classList.remove('active'));
    
    // Activate selected module
    document.getElementById(`mod-${moduleName}`).classList.add('active');
    document.getElementById(`${moduleName}-module`).classList.add('active');
    
    if (moduleName === 'security') {
        scanThreats();
    }
}

function terminate() {
    document.getElementById('app').style.display = 'none';
    fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

function scanTargets() {
    const search = document.getElementById('playerSearch').value.toLowerCase();
    const filtered = targets.filter(target => 
        target.name.toLowerCase().includes(search) || 
        target.id.toString().includes(search)
    );
    renderTargets(filtered);
}

function renderTargets(targetList) {
    const grid = document.getElementById('targetsGrid');
    grid.innerHTML = '';
    
    targetList.forEach(target => {
        const operations = [
            { op: 'gotoo', name: 'Goto', danger: false },
            { op: 'bring', name: 'Bring', danger: false },
            { op: 'heal', name: 'Heal', danger: false },
            { op: 'revive', name: 'Revive', danger: false },
            { op: 'armor', name: 'Armor', danger: false },
            { op: 'openinv', name: 'Inventory', danger: false },
            { op: 'kick', name: 'Kick', danger: true },
            { op: 'ban', name: 'Ban', danger: true }
        ];
        
        let actionsHTML = '';
        operations.forEach(operation => {
            if (permissions.includes(operation.op)) {
                actionsHTML += `
                    <div class="action ${operation.danger ? 'danger' : ''}" 
                         onclick="executeOperation('${operation.op}', ${target.id})">
                        ${operation.name}
                    </div>
                `;
            }
        });
        
        const targetCard = document.createElement('div');
        targetCard.className = 'target-card';
        targetCard.innerHTML = `
            <div class="target-header">
                <div class="target-id">ID: ${target.id}</div>
                <div class="target-ping">${target.ping}ms</div>
            </div>
            <div class="target-name">${target.name}</div>
            <div class="target-job">${target.job}</div>
            <div class="target-actions">
                ${actionsHTML}
            </div>
        `;
        
        grid.appendChild(targetCard);
    });
}

function executeOperation(operation, targetId) {
    let reason = null;
    if (operation === 'kick' || operation === 'ban') {
        reason = prompt(`ENTER REASON FOR ${operation.toUpperCase()}:`);
        if (!reason) return;
    }
    
    const payload = {
        action: operation,
        targetId: targetId,
        reason: reason
    };
    
    fetch(`https://${GetParentResourceName()}/doAction`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
    }).then(() => {
        if (operation === 'kick' || operation === 'ban') {
            targets = targets.filter(t => t.id != targetId);
            renderTargets(targets);
        }
    });
}

function deployWeapon(weapon) {
    fetch(`https://${GetParentResourceName()}/doAction`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: weapon })
    });
}

function scanThreats() {
    fetch(`https://${GetParentResourceName()}/getBanList`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    })
    .then(response => response.json())
    .then(threats => {
        const container = document.getElementById('threatsList');
        container.innerHTML = '';
        
        threats.forEach(threat => {
            const threatItem = document.createElement('div');
            threatItem.className = 'threat-item';
            
            threatItem.innerHTML = `
                <div class="threat-info">
                    <h4>Ban: ${threat.name}</h4>
                    <p>ADMIN: ${threat.admin} | REASON: ${threat.reason} | DATE: ${threat.date}</p>
                </div>
                <button class="neutralize" onclick="neutralizeThreat('${threat.identifiers ? threat.identifiers[0] : threat.license}')">
                    Unban
                </button>
            `;
            
            container.appendChild(threatItem);
        });
    });
}

function neutralizeThreat(license) {
    fetch(`https://${GetParentResourceName()}/doAction`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ action: 'unban', license: license })
    }).then(() => {
        scanThreats();
    });
}

// System initialization
window.addEventListener('message', (event) => {
    const data = event.data;
    
    if (data.type === 'OPEN') {
        targets = data.players;
        permissions = data.perms;
        
        document.getElementById('app').style.display = 'flex';
        renderTargets(targets);
    }
});

// Emergency shutdown
document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') {
        terminate();
    }
});