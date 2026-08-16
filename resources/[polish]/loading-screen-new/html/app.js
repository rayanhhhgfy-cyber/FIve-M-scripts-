const { ref } = Vue

// Customize language for dialog menus and carousels here

const load = Vue.createApp({
  setup () {
    return {
      CarouselText1: 'You can add/remove items, vehicles, jobs & gangs through the shared folder.',
      CarouselSubText1: 'Photo captured by: Markyoo#8068',
      CarouselText2: 'Adding additional player data can be achieved by modifying the qb-core player.lua file.',
      CarouselSubText2: 'Photo captured by: ihyajb#9723',
      CarouselText3: 'All server-specific adjustments can be made in the config.lua files throughout the build.',
      CarouselSubText3: 'Photo captured by: FLAPZ[INACTIV]#9925',
      CarouselText4: 'For additional support please join our community at discord.gg/qbcore',
      CarouselSubText4: 'Photo captured by: Robinerino#1312',

      DownloadTitle: 'Downloading QBCore Server',
      DownloadDesc: "Hold tight while we begin downloading all the resources/assets required to play on QBCore Server. \n\nAfter download has been finished successfully, you'll be placed into the server and this screen will disappear. Please don't leave or turn off your PC. ",
      CarouselText1: 'Customize your character appearance, outfits, and gear from any wardrobe/clothing store.',
      CarouselSubText1: 'High-quality MLOs and custom layouts integrated throughout the city.',
      CarouselText2: 'Centralized QBox configuration allows seamless interaction across all gameplay mechanics.',
      CarouselSubText2: ' Centralized database stores persistent assets, housing, vehicles, and progression.',
      CarouselText3: 'Access interactive features like vehicle doors, windows, keys, and seats via F1 Radial Menu.',
      CarouselSubText3: ' Centralized configurations allow for full server-wide synchronization.',
      CarouselText4: 'For server updates, rules, commands, and keybinds, use the /rules command in game.',
      CarouselSubText4: 'Designed to offer the ultimate custom roleplay experience.',

      DownloadTitle: 'Loading QBox Roleplay Server',
      DownloadDesc: "Hold tight while we download and synchronize all the custom resources and assets required to play on the server. \n\nOnce the load is complete, you'll spawn into the world seamlessly. Please do not close your game or turn off your PC.",

      SettingsTitle: 'Settings',
      AudioTrackDesc1: 'When disabled the current audio-track playing will be stopped.',
      AutoPlayDesc2: 'When disabled carousel images will stop cycling and remain on the last shown.',
      PlayVideoDesc3: 'When disabled video will stop playing and remain paused.',

      KeybindTitle: 'Default Keybinds',
      Keybind1: 'Open Inventory',
      Keybind2: 'Cycle Proximity',
      Keybind3: 'Open Phone',
      Keybind4: 'Toggle Seat Belt',
      Keybind5: 'Open Target Menu',
      Keybind6: 'Radial Menu',
      Keybind7: 'Open Hud Menu',
      Keybind8: 'Talk Over Radio',
      Keybind9: 'Open Scoreboard',
      Keybind10: 'Vehicle Locks',
      Keybind11: 'Toggle Engine',
      Keybind12: 'Pointer Emote',
      Keybind13: 'Keybind Slots',
      Keybind14: 'Hands Up Emote',
      Keybind15: 'Use Item Slots',
      Keybind16: 'Cruise Control',

      firstap: ref(true),
      secondap: ref(true),
      thirdap: ref(true),
      firstslide: ref(1),
      secondslide: ref('1'),
      thirdslide: ref('5'),
      audioplay: ref(true),
      playvideo: ref(true),
      download: ref(true),
      settings: ref(false),
    }
  }
})

load.use(Quasar, { config: {} })
load.mount('#loading-main')

var audio = document.getElementById("audio");
audio.volume = 0.05;

function audiotoggle() {
    var audio = document.getElementById("audio");
    if (audio.paused) {
        audio.play();
    } else {
        audio.pause();
    }
}

function videotoggle() {
    var video = document.getElementById("video");
    if (video.paused) {
        video.play();
    } else {
        video.pause();
    }
}

let count = 0;
let thisCount = 0;

const handlers = {
    startInitFunctionOrder(data) {
        count = data.count;
    },

    initFunctionInvoking(data) {
        document.querySelector(".thingy").style.left = "0%";
        document.querySelector(".thingy").style.width = (data.idx / count) * 100 + "%";
    },

    startDataFileEntries(data) {
        count = data.count;
    },

    performMapLoadFunction(data) {
        ++thisCount;

        document.querySelector(".thingy").style.left = "0%";
        document.querySelector(".thingy").style.width = (thisCount / count) * 100 + "%";
    },
};

window.addEventListener("message", function (e) {
    (handlers[e.data.eventName] || function () {})(e.data);
});
