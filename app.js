'use strict';

(() => {
  const looks = window.ROLAND_LOOKS;
  const $ = (selector) => document.querySelector(selector);
  const stage = $('#stage');
  const video = $('#video');
  const still = $('#still');
  const panel = $('#panel');
  const grid = $('#lookGrid');
  const KEY = 'roland-wallpaper-v1';
  const defaults = { index: 3, mode: 'freeze', group: 'standing', favorites: [], brightness: 100, volume: 35, sound: false, autohide: true, fit: 'contain', autoswitch: 0, textsize: 'medium', layout: 'left' };
  let state = loadState();
  let autoHideTimer = null;
  let autoSwitchTimer = null;
  let toastTimer = null;
  let dialogueCursor = 0;

  function loadState() {
    try { return { ...defaults, ...JSON.parse(localStorage.getItem(KEY) || '{}') }; }
    catch { return { ...defaults }; }
  }
  function saveState() { localStorage.setItem(KEY, JSON.stringify(state)); }
  function current() { return looks[Math.max(0, Math.min(looks.length - 1, state.index))]; }
  function playablePool() { const pool = state.mode === 'favorites' ? looks.filter(x => state.favorites.includes(x.id)) : looks; return pool.length ? pool : looks; }

  function renderGrid() {
    grid.textContent = '';
    looks.filter(x => x.group === state.group).forEach(look => {
      const button = document.createElement('button');
      button.className = `look-card${look.index === state.index ? ' active' : ''}`;
      button.title = look.name;
      button.innerHTML = `<img src="${look.thumb}" alt="" loading="lazy"><span>${look.name}</span>`;
      button.querySelector('img').addEventListener('error', (event) => { event.currentTarget.style.display = 'none'; });
      button.addEventListener('click', () => selectLook(look.index, true));
      grid.append(button);
    });
  }

  async function selectLook(index, announce = false) {
    state.index = (index + looks.length) % looks.length;
    const look = current();
    state.group = look.group;
    saveState();
    dialogueCursor = (dialogueCursor + 1) % look.dialogue.length;
    $('#dialogueText').textContent = look.dialogue[dialogueCursor];
    still.src = look.image;
    still.alt = `${look.name} — Roland`;
    video.pause();
    video.src = look.video;
    video.volume = state.volume / 100;
    video.muted = !state.sound;
    stage.classList.remove('playing');
    video.addEventListener('loadeddata', startPlayback, { once: true });
    video.addEventListener('error', () => stage.classList.remove('playing'), { once: true });
    renderMeta();
    renderGrid();
    if (announce) toast(`已换上「${look.name}」`);
  }

  async function startPlayback() {
    const look = current();
    try {
      if (state.mode === 'freeze') {
        video.currentTime = Math.min(look.freeze, Number.isFinite(video.duration) ? Math.max(0, video.duration - .05) : look.freeze);
        video.pause();
        stage.classList.add('playing');
      } else {
        video.currentTime = 0;
        video.loop = false;
        await video.play();
        stage.classList.add('playing');
      }
    } catch { stage.classList.remove('playing'); }
  }

  function renderMeta() {
    const look = current();
    $('#currentIndex').textContent = `${String(look.index + 1).padStart(2, '0')} / ${looks.length}`;
    $('#currentName').textContent = look.name;
    $('#currentEnglish').textContent = look.english;
    $('#favoriteButton').textContent = state.favorites.includes(look.id) ? '★' : '☆';
    document.querySelectorAll('[data-mode]').forEach(x => x.classList.toggle('active', x.dataset.mode === state.mode));
    document.querySelectorAll('[data-group]').forEach(x => x.classList.toggle('active', x.dataset.group === state.group));
  }

  function applySettings() {
    document.documentElement.style.setProperty('--wall-brightness', `${state.brightness}%`);
    [still, video].forEach(el => { el.style.filter = `brightness(${state.brightness}%)`; el.style.objectFit = state.fit; });
    video.volume = state.volume / 100; video.muted = !state.sound;
    stage.classList.toggle('layout-right', state.layout === 'right');
    stage.classList.remove('text-small', 'text-medium', 'text-large'); stage.classList.add(`text-${state.textsize}`);
    $('#brightness').value = state.brightness; $('#brightnessValue').value = `${state.brightness}%`;
    $('#volume').value = state.volume; $('#volumeValue').value = `${state.volume}%`;
    $('#sound').checked = state.sound; $('#autohide').checked = state.autohide;
    $('#fit').value = state.fit; $('#autoswitch').value = String(state.autoswitch);
    $('#textsize').value = state.textsize; $('#layout').value = state.layout;
    configureAutoSwitch();
  }

  function setPanel(open) { panel.classList.toggle('hidden', !open); $('#panelToggle').classList.toggle('visible', !open); if (open) armAutoHide(); }
  function armAutoHide() { clearTimeout(autoHideTimer); if (state.autohide) autoHideTimer = setTimeout(() => setPanel(false), 15000); }
  function configureAutoSwitch() { clearInterval(autoSwitchTimer); if (+state.autoswitch > 0) autoSwitchTimer = setInterval(() => randomLook(false), +state.autoswitch * 60000); }
  function move(delta) { const pool = playablePool(); const at = pool.findIndex(x => x.id === current().id); selectLook(pool[(at + delta + pool.length) % pool.length].index, true); }
  function randomLook(announce = true) { const pool = playablePool().filter(x => x.id !== current().id); selectLook((pool[Math.floor(Math.random() * pool.length)] || current()).index, announce); }
  function toggleFavorite() { const id = current().id; state.favorites = state.favorites.includes(id) ? state.favorites.filter(x => x !== id) : [...state.favorites, id]; saveState(); renderMeta(); toast(state.favorites.includes(id) ? '已收藏' : '已取消收藏'); }
  function toast(text) { const el = $('#toast'); el.textContent = text; el.classList.add('show'); clearTimeout(toastTimer); toastTimer = setTimeout(() => el.classList.remove('show'), 1700); }

  document.querySelectorAll('[data-mode]').forEach(button => button.addEventListener('click', () => { state.mode = button.dataset.mode; saveState(); renderMeta(); startPlayback(); }));
  document.querySelectorAll('[data-group]').forEach(button => button.addEventListener('click', () => { state.group = button.dataset.group; saveState(); renderMeta(); renderGrid(); }));
  $('#previousButton').addEventListener('click', () => move(-1)); $('#nextButton').addEventListener('click', () => move(1));
  $('#randomButton').addEventListener('click', () => randomLook()); $('#favoriteButton').addEventListener('click', toggleFavorite);
  $('#closePanel').addEventListener('click', () => setPanel(false)); $('#panelToggle').addEventListener('click', () => setPanel(true));
  panel.addEventListener('pointermove', armAutoHide); panel.addEventListener('click', armAutoHide);
  [['brightness',Number],['volume',Number],['fit',String],['autoswitch',Number],['textsize',String],['layout',String]].forEach(([id, cast]) => $(`#${id}`).addEventListener('input', event => { state[id] = cast(event.target.value); saveState(); applySettings(); }));
  ['sound','autohide'].forEach(id => $(`#${id}`).addEventListener('change', event => { state[id] = event.target.checked; saveState(); applySettings(); armAutoHide(); }));
  video.addEventListener('ended', () => { if (state.mode === 'single') stage.classList.remove('playing'); else if (state.mode === 'cycle' || state.mode === 'favorites') move(1); });
  window.addEventListener('keydown', event => { if (event.key === 'ArrowLeft') move(-1); if (event.key === 'ArrowRight') move(1); if (event.key.toLowerCase() === 'r') randomLook(); if (event.key.toLowerCase() === 'f') toggleFavorite(); if (event.key === 'Escape') setPanel(false); });

  window.wallpaperPropertyListener = { applyUserProperties(properties) {
    const map = { brightness:'brightness', volume:'volume', sound:'sound', autohide:'autohide', fit:'fit', autoswitch:'autoswitch' };
    Object.entries(map).forEach(([source,target]) => { if (properties[source]) state[target] = properties[source].value; });
    if (properties.look && String(properties.look.value) !== '0') { const found = looks.findIndex(x => x.id === String(properties.look.value).padStart(2,'0')); if (found >= 0) state.index = found; }
    saveState(); applySettings(); selectLook(state.index);
  }};

  applySettings(); renderGrid(); selectLook(state.index); armAutoHide();
})();
