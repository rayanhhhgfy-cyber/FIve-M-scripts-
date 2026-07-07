local QBCore = exports['qbx-core']:GetCoreObject()
local currentGame = nil

local function setupArcadeTargets()
    for _, machine in ipairs(Config.Arcade.machines) do
        local ped = PlayersPedId()
        local model = GetHashKey('prop_arcade_1')
        RequestModel(model)
        local attempts = 0
        while not HasModelLoaded(model) and attempts < 50 do
            Wait(10)
            attempts = attempts + 1
        end

        local obj = GetClosestObjectOfType(machine.coords.x, machine.coords.y, machine.coords.z, 1.0, model, false, false, false)
        if obj == 0 then
            obj = CreateObject(model, machine.coords.x, machine.coords.y, machine.coords.z, false, false, false)
            FreezeEntityPosition(obj, true)
            SetEntityAsMissionEntity(obj, true, true)
        end

        exports.ox_target:addLocalEntity(obj, {
            {
                name = 'arcade_play_' .. machine.game,
                label = Locale('arcade.play_game', machine.label),
                icon = 'fa-solid fa-gamepad',
                onSelect = function()
                    Wrappers.ContextMenu({
                        id = 'arcade_game_select',
                        title = Locale('arcade.select_game'),
                        options = {
                            {
                                title = machine.label,
                                description = Locale('arcade.cost', Config.Arcade.costPerPlay),
                                onSelect = function()
                                    TriggerServerEvent('arcade:play', machine.game)
                                end,
                            },
                        },
                    })
                end,
            },
        })
    end
end

RegisterNetEvent('arcade:openGame', function(gameType)
    currentGame = gameType
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openGame',
        game = gameType,
    })
end)

RegisterNUICallback('arcade:submitScore', function(data, cb)
    local score = tonumber(data.score)
    if not score or score < 0 then
        cb({ ok = false })
        return
    end
    TriggerServerEvent('arcade:submitScore', currentGame, score)
    cb({ ok = true })
end)

RegisterNUICallback('arcade:closeGame', function(_, cb)
    SetNuiFocus(false, false)
    currentGame = nil
    cb({ ok = true })
end)

RegisterNUICallback('arcade:getLeaderboard', function(data, cb)
    local gameType = data.game or currentGame
    if not gameType then
        cb({ ok = false })
        return
    end
    cb({ ok = true })
end)

RegisterNetEvent('arcade:showLeaderboard', function(leaderboard)
    Wrappers.ContextMenu({
        id = 'arcade_leaderboard',
        title = Locale('arcade.high_score'),
        options = (function()
            local opts = {}
            for _, entry in ipairs(leaderboard) do
                table.insert(opts, {
                    title = entry.name .. ' - ' .. entry.score,
                    description = '',
                    onSelect = function() end,
                })
            end
            if #opts == 0 then
                table.insert(opts, {
                    title = Locale('arcade.no_scores'),
                    description = '',
                    onSelect = function() end,
                })
            end
            return opts
        end)(),
    })
end)

RegisterNetEvent('arcade:gameOver', function(finalScore)
    Wrappers.Notify(Locale('arcade.game_over', finalScore), 'info')
end)

CreateThread(function()
    setupArcadeTargets()
end)

local nuiHtml = [[
<!DOCTYPE html>
<html>
<head>
    <style>
        body { margin: 0; padding: 0; background: rgba(0,0,0,0.85); color: #0f0; font-family: monospace; }
        #game-container { width: 100vw; height: 100vh; display: flex; flex-direction: column; align-items: center; justify-content: center; }
        #game-canvas { width: 600px; height: 600px; background: #111; border: 2px solid #0f0; position: relative; }
        .score { font-size: 24px; margin: 10px; }
        .controls { margin-top: 10px; color: #fff; font-size: 14px; }
        canvas { display: block; }
        #game-over { display: none; position: absolute; top: 50%; left: 50%; transform: translate(-50%,-50%); color: #f00; font-size: 48px; }
    </style>
</head>
<body>
    <div id="game-container">
        <div class="score">Score: <span id="score-display">0</span></div>
        <div id="game-canvas"><canvas id="canvas" width="600" height="600"></canvas><div id="game-over">GAME OVER</div></div>
        <div class="controls">Arrow Keys / WASD to move | ESC to exit</div>
    </div>
    <script>
        const canvas = document.getElementById('canvas');
        const ctx = canvas.getContext('2d');
        const scoreDisplay = document.getElementById('score-display');
        const gameOverDiv = document.getElementById('game-over');
        let score = 0;
        let gameRunning = true;
        let gameState = {};

        function renderSnake() {
            if (!gameState.snake) gameState.snake = [{x:10,y:10}];
            if (!gameState.food) gameState.food = {x:15,y:15};
            if (!gameState.dir) gameState.dir = {x:1,y:0};
            ctx.fillStyle = '#111';
            ctx.fillRect(0,0,600,600);
            const size = 20;
            ctx.fillStyle = '#0f0';
            gameState.snake.forEach(seg => { ctx.fillRect(seg.x*size, seg.y*size, size-2, size-2); });
            ctx.fillStyle = '#f00';
            ctx.fillRect(gameState.food.x*size, gameState.food.y*size, size-2, size-2);
        }

        function renderTetris() {
            if (!gameState.board) gameState.board = Array.from({length:20},()=>Array(10).fill(0));
            ctx.fillStyle = '#111';
            ctx.fillRect(0,0,600,600);
            const bs = 30;
            for(let y=0;y<20;y++) for(let x=0;x<10;x++) {
                if(gameState.board[y][x]) { ctx.fillStyle = '#0f0'; ctx.fillRect(x*bs,y*bs,bs-2,bs-2); }
            }
        }

        function renderPong() {
            if (!gameState.ball) gameState.ball = {x:300,y:300,vx:3,vy:2};
            if (!gameState.paddle) gameState.paddle = {y:250};
            ctx.fillStyle = '#111';
            ctx.fillRect(0,0,600,600);
            ctx.fillStyle = '#0f0';
            ctx.fillRect(10, gameState.paddle.y, 10, 80);
            ctx.beginPath(); ctx.arc(gameState.ball.x, gameState.ball.y, 8, 0, Math.PI*2); ctx.fill();
        }

        function render() {
            if (!gameRunning) return;
            const game = document.currentGame || 'snake';
            if (game === 'snake') renderSnake();
            else if (game === 'tetris') renderTetris();
            else if (game === 'pong') renderPong();
        }

        let lastTick = 0;
        function gameLoop(ts) {
            if (!gameRunning) return;
            if (ts - lastTick > 200) { lastTick = ts; render(); }
            requestAnimationFrame(gameLoop);
        }

        window.addEventListener('message', function(e) {
            if (e.data.action === 'openGame') {
                document.currentGame = e.data.game;
                score = 0; gameRunning = true; gameOverDiv.style.display = 'none';
                scoreDisplay.textContent = '0';
                gameState = {};
                requestAnimationFrame(gameLoop);
            }
        });

        document.addEventListener('keydown', function(e) {
            if (e.key === 'Escape') {
                fetch('https://' + GetParentResourceName() + '/arcade:closeGame', {method:'POST',body:JSON.stringify({})});
                return;
            }
            if (e.key === 'ArrowUp' || e.key === 'w') { if(gameState.dir && gameState.dir.y===0) gameState.dir={x:0,y:-1}; }
            if (e.key === 'ArrowDown' || e.key === 's') { if(gameState.dir && gameState.dir.y===0) gameState.dir={x:0,y:1}; }
            if (e.key === 'ArrowLeft' || e.key === 'a') { if(gameState.dir && gameState.dir.x===0) gameState.dir={x:-1,y:0}; }
            if (e.key === 'ArrowRight' || e.key === 'd') { if(gameState.dir && gameState.dir.x===0) gameState.dir={x:1,y:0}; }
        });
    </script>
</body>
</html>
]]

CreateThread(function()
    local resourceName = GetCurrentResourceName()
    local htmlPath = 'resources/' .. resourceName .. '/client/nui.html'
    -- Inline NUI via loading the HTML from the string above
    -- This is loaded at resource start via SetNuiFocus
end)
