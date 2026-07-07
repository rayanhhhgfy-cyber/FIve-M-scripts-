let emoteData = null
let favoriteEmotes = {}
let currentCategory = 'favorites'
let searchQuery = ''

const categoryIcons = {
    Dances: 'fa-music',
    Gestures: 'fa-hand-peace',
    Idles: 'fa-person',
    Expressions: 'fa-face-smile',
    Greetings: 'fa-hand-wave',
    Actions: 'fa-running',
    Miscellaneous: 'fa-ellipsis'
}

window.addEventListener('message', function(event) {
    const data = event.data
    if (data.action === 'openEmoteMenu') {
        emoteData = data.data.categories
        favoriteEmotes = data.data.favorites || {}
        renderCategories()
        renderEmotes()
        document.getElementById('emote-menu').style.display = 'flex'
    }
})

function renderCategories() {
    const container = document.getElementById('emote-categories')
    container.innerHTML = '<div id="emote-cat-favorites" class="emote-category active" data-cat="favorites"><i class="fas fa-star"></i><span>Favorites</span></div>'
    for (const cat in emoteData) {
        const div = document.createElement('div')
        div.className = 'emote-category' + (cat === currentCategory ? ' active' : '')
        div.dataset.cat = cat
        const icon = categoryIcons[cat] || 'fa-folder'
        div.innerHTML = '<i class="fas ' + icon + '"></i><span>' + cat + '</span>'
        div.addEventListener('click', function() {
            document.querySelectorAll('.emote-category').forEach(el => el.classList.remove('active'))
            div.classList.add('active')
            currentCategory = cat
            searchQuery = ''
            document.getElementById('emote-search').value = ''
            renderEmotes()
        })
        container.appendChild(div)
    }
    document.getElementById('emote-cat-favorites').addEventListener('click', function() {
        document.querySelectorAll('.emote-category').forEach(el => el.classList.remove('active'))
        this.classList.add('active')
        currentCategory = 'favorites'
        searchQuery = ''
        document.getElementById('emote-search').value = ''
        renderEmotes()
    })
}

function renderEmotes() {
    const grid = document.getElementById('emote-grid')
    grid.innerHTML = ''

    let items = []
    if (currentCategory === 'favorites') {
        for (const key in favoriteEmotes) {
            const parts = key.split('|')
            const cat = parts[0]
            const name = parts[1]
            if (emoteData[cat]) {
                for (const emote of emoteData[cat]) {
                    if (emote.name === name) {
                        items.push({ emote: emote, category: cat })
                    }
                }
            }
        }
    } else if (emoteData[currentCategory]) {
        for (const emote of emoteData[currentCategory]) {
            items.push({ emote: emote, category: currentCategory })
        }
    }

    if (searchQuery) {
        const q = searchQuery.toLowerCase()
        items = items.filter(item => item.emote.name.toLowerCase().includes(q))
    }

    if (items.length === 0) {
        grid.innerHTML = '<div class="emote-no-results">' + (searchQuery ? 'No emotes found' : 'No favorites yet. Star emotes to add them here!') + '</div>'
        document.getElementById('emote-preview-name').textContent = 'Select an emote'
        document.getElementById('emote-preview-category').textContent = ''
        return
    }

    for (const item of items) {
        const div = document.createElement('div')
        div.className = 'emote-item'
        const emoteKey = item.category + '|' + item.emote.name
        const isFav = !!favoriteEmotes[emoteKey]
        div.innerHTML = '<span>' + item.emote.name + '</span><button class="fav-btn' + (isFav ? ' favorited' : '') + '" data-key="' + emoteKey + '"><i class="' + (isFav ? 'fas' : 'far') + ' fa-star"></i></button>'
        div.addEventListener('click', function(e) {
            if (e.target.closest('.fav-btn')) return
            fetch('https://' + GetParentResourceName() + '/emotePlay', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ category: item.category, name: item.emote.name })
            })
        })
        div.querySelector('.fav-btn').addEventListener('click', function(e) {
            e.stopPropagation()
            const key = this.dataset.key
            const currentlyFav = !!favoriteEmotes[key]
            if (currentlyFav) {
                delete favoriteEmotes[key]
                this.classList.remove('favorited')
                this.querySelector('i').className = 'far fa-star'
            } else {
                favoriteEmotes[key] = true
                this.classList.add('favorited')
                this.querySelector('i').className = 'fas fa-star'
            }
            fetch('https://' + GetParentResourceName() + '/emoteFavorite', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ category: item.category, name: item.emote.name, favorited: !currentlyFav })
            })
        })
        div.addEventListener('mouseenter', function() {
            document.getElementById('emote-preview-name').textContent = item.emote.name
            document.getElementById('emote-preview-category').textContent = item.category
        })
        grid.appendChild(div)
    }
}

document.getElementById('emote-search').addEventListener('input', function() {
    searchQuery = this.value
    renderEmotes()
})

document.getElementById('emote-close').addEventListener('click', function() {
    fetch('https://' + GetParentResourceName() + '/emoteClose', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    })
})

document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        fetch('https://' + GetParentResourceName() + '/emoteClose', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        })
    }
})

function GetParentResourceName() {
    return window.location.hostname
}
