// We import the CSS which is extracted to its own file by esbuild.
// Remove this line if you add a your own CSS build pipeline (e.g postcss).
// import "../css/app.css"

// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "./vendor/some-package.js"
//
// Alternatively, you can `npm install some-package` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import 'phoenix_html';
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from 'phoenix';
import { LiveSocket } from 'phoenix_live_view';
import topbar from 'topbar';
import map from './map';
import clipboard from './clipboard';
import dropdown from './dropdown';
import bracketLiveParticipant from './bracket-live-participant';
import flatpickr from './flatpickr';
import pickr from './pickr';
import glide from './glide';
import follow from './follow';
import modal from './modal';
import sortable from './sortable';
import twitch from './twitch';
import qrcode from './qrcode';
import flash from './flash';
import cheatcodes from './cheatcodes';
import passwordInput from './passwordInput';
import prizePoolDisplay from './prizePoolDisplay';
import profileScroll from './profileScroll';
import tournamentFullscreenScroll from './tournamentFullscreenScroll';
import remover from './remover';
import rosterManager from './rosterManager';
import matchesGraph from './matches-graph';
import matchParticipantSwitcher from './match-participant-switcher';
import poolGroup from './pool-group';
import segment from './segment';
import theme from './theme';
import navbar from './navbar';
import navbarMargin from './navbarMargin';
import tournamentHoverGroup from './tournamentHoverGroup';
import pushEventOnKey from './push-event-on-key';
import ScrollIntoView from './scroll_into_view';
import clickAndGrabScroll from './click_and_grab_scroll';

import Alpine from 'alpinejs';
import focus from '@alpinejs/focus';

import Dropzone from 'dropzone';
import Croppie from 'croppie';

import setCountdown from './setCountdown';

import resolveConfig from 'tailwindcss/resolveConfig';
import tailwindConfig from '../tailwind.config.js';
import './qrcodelib.js';

const fullTailwindConfig = resolveConfig(tailwindConfig);

window.Alpine = Alpine;
Alpine.data('bracketLiveParticipant', bracketLiveParticipant);
Alpine.data('dropdown', dropdown);

Alpine.data('follow', follow);
Alpine.data('modal', modal);
Alpine.data('passwordInput', passwordInput);
Alpine.data('remover', remover);
Alpine.data('rosterManager', rosterManager);
Alpine.data('theme', theme);
Alpine.data('poolGroup', poolGroup);
Alpine.data('prizePoolDisplay', prizePoolDisplay);
Alpine.data('profileScroll', profileScroll);
Alpine.data('tournamentFullscreenScroll', tournamentFullscreenScroll);
Alpine.data('navbar', navbar);
Alpine.data('navbarMargin', navbarMargin);
Alpine.data('tournamentHoverGroup', tournamentHoverGroup);
Alpine.start();
Alpine.plugin(focus);

let csrfToken = document
  .querySelector("meta[name='csrf-token']")
  .getAttribute('content');

const colors = fullTailwindConfig.theme.colors;

let hooks = {
  Map: map,
  Pickr: pickr
};

hooks = { ...hooks, ...twitch().hooks };
hooks = { ...hooks, ...flash().hooks };
hooks = { ...hooks, ...cheatcodes().hooks };
hooks = { ...hooks, ...matchesGraph({ colors }).hooks };
hooks = { ...hooks, ...flatpickr().hooks };
hooks = { ...hooks, ...glide().hooks };
hooks = { ...hooks, ...sortable().hooks };
hooks = { ...hooks, ...qrcode().hooks };
hooks = { ...hooks, ...pushEventOnKey().hooks };
hooks = { ...hooks, ...clickAndGrabScroll().hooks };
hooks = { ...hooks, ...ScrollIntoView().hooks };

let Uploaders = {};
Uploaders.S3 = function (entries, onViewError) {
  entries.forEach(entry => {
    let formData = new FormData();
    let { url, fields } = entry.meta;

    Object.entries(fields).forEach(([key, val]) => formData.append(key, val));
    formData.append('file', entry.file);
    let xhr = new XMLHttpRequest();
    onViewError(() => xhr.abort());
    xhr.onload = () =>
      xhr.status === 204 || 200 ? entry.progress(100) : entry.error();
    xhr.onerror = () => entry.error();
    xhr.upload.addEventListener('progress', event => {
      if (event.lengthComputable) {
        let percent = Math.round((event.loaded / event.total) * 100);
        if (percent < 100) {
          entry.progress(percent);
        }
      }
    });
    xhr.open('POST', url, true);
    xhr.send(formData);
  });
};

hooks.InterestedPlayer = {
  mounted() {
    this.handleEvent('interest_registered', ({ interest_registered }) =>
      localStorage.setItem('interest_registered', interest_registered)
    );
  }
};

hooks.CreateStake = {
  mounted() {
    const moneyInputs = this.el.getElementsByClassName('money-amount__input');
    if (moneyInputs.length) {
      const moneyInput = moneyInputs[0];
      moneyInput.focus();
      moneyInput.select();
    }
  }
};

const displayFontFamiliesString =
  fullTailwindConfig.theme.fontFamily.display.join(', ');

hooks.FileUpload = {
  mounted() {
    const pushEventToComponent = (event, payload) => {
      this.pushEventTo(this.el, event, payload);
    };
    function dataURItoBlob(dataURI) {
      var byteString = atob(dataURI.split(',')[1]);
      var arrayBuffer = new ArrayBuffer(byteString.length);
      var unitArray = new Uint8Array(arrayBuffer);
      for (var i = 0; i < byteString.length; i++) {
        unitArray[i] = byteString.charCodeAt(i);
      }
      return new Blob([arrayBuffer], { type: 'image/jpeg' });
    }

    let croppie;
    let croppieDimensions = {
      hView: parseInt(this.el.getAttribute('h-view')),
      wView: parseInt(this.el.getAttribute('w-view')),
      hUpload: parseInt(this.el.getAttribute('h-upload')),
      wUpload: parseInt(this.el.getAttribute('w-upload'))
    };

    let clickable;
    if (this.el.querySelector('.clickable')) {
      clickable = this.el.querySelector('.clickable');
    } else {
      let clickable_selector = this.el
        .querySelector('.get-clickable')
        .getAttribute('selector');
      clickable = document.querySelector(clickable_selector);
    }

    let uploader = new Dropzone(this.el, {
      acceptedFiles: 'image/*',
      parallelUploads: 1,
      maxFiles: 1,
      thumbnailWidth: null,
      thumbnailHeight: null,
      autoProcessQueue: false,
      clickable: clickable,
      previewsContainer: this.el.querySelector('div.dropzonepreviews'),
      headers: {
        'x-csrf-token': csrfToken
      }
    });

    this.el
      .querySelector('button[type=submit]')
      .addEventListener('click', async function (e) {
        e.preventDefault();
        e.stopPropagation();
        if (croppie) {
          cropped_data = await croppie.result({
            type: 'base64',
            size: {
              width: croppieDimensions.wUpload,
              height: croppieDimensions.hUpload
            },
            format: 'jpeg',
            circle: false
          });

          cropped_image = dataURItoBlob(cropped_data);

          cropped_image.cropped = true;

          uploader.addFile(cropped_image);

          uploader.processQueue();
        } else {
          pushEventToComponent('error_profile_picture');
        }
      });
    uploader.image_preview = this.el.querySelector('div.uploaded-image');
    uploader.upload_dialog = this.el.querySelector('div.upload-dialog');

    uploader.image_preview
      .querySelector('.remove-image')
      .addEventListener('click', function (e) {
        uploader.image_preview.classList.add('hidden');
        uploader.upload_dialog.classList.remove('hidden');
      });

    uploader.on('thumbnail', function (file, dataURL) {
      if (file.cropped) return;
      try {
        croppie = new Croppie(this.element.querySelector('.croppie'), {
          viewport: {
            width: croppieDimensions.wView,
            height: croppieDimensions.hView
          },
          boundary: {
            width: croppieDimensions.wView + 100,
            height: croppieDimensions.hView + 100
          }
        });
      } catch (e) {}

      if (croppie) {
        croppie.bind({
          url: dataURL
        });
        this.image_preview.classList.remove('hidden');
        this.upload_dialog.classList.add('hidden');
      } else {
        pushEventToComponent('error_profile_picture');
      }
      this.removeFile(file);
    });
    uploader.on('error', function (file, message) {
      this.removeFile(file);
      pushEventToComponent('error_profile_picture');
    });
    uploader.on('success', function (file) {
      this.removeFile(file);
      pushEventToComponent('update_profile_picture');
      this.image_preview.classList.add('hidden');
      this.upload_dialog.classList.remove('hidden');
    });
  }
};

hooks.Captcha = {
  mounted() {
    this.handleEvent('create_captcha', function (payload) {
      payload.theme = 'dark';
      const signupCaptcha = document.getElementById('signupCaptcha');
      hcaptcha.render(signupCaptcha, payload);
    });
    this.handleEvent('reset_captcha', function (payload) {
      hcaptcha.reset();
    });
  }
};

// Alpine JS x-data strings where we want the state to be preserved across LiveView updates
const stickyXDatas = ['poolGroup'];

let liveSocket = new LiveSocket('/live', Socket, {
  params: {
    _csrf_token: csrfToken,
    interest_registered: localStorage.getItem('interest_registered') || false
  },
  uploaders: Uploaders,
  hooks: hooks,
  dom: {
    onNodeAdded(node) {
      if (node._x_dataStack) {
        window.Alpine.initTree(node);
      }
    },
    onBeforeElUpdated(from, to) {
      if (from._x_dataStack) {
        window.Alpine.clone(from, to);
        if (stickyXDatas.includes(from.getAttribute('x-init'))) {
          window.Alpine.initTree(to);
        }
      }
    }
  }
});

// Topbar configuration: Show progress bar on live navigation and form submits
topbar.config({
  barColors: { 0: '#ff6802', 0.6: '#03d5fb' },
  shadowColor: '#ff680200'
});

let topBarScheduled = undefined;
window.addEventListener('phx:page-loading-start', () => {
  if (!topBarScheduled) {
    topBarScheduled = setTimeout(() => topbar.show(), 200);
  }
});

window.addEventListener('phx:page-loading-stop', info => {
  clearTimeout(topBarScheduled);
  topBarScheduled = undefined;
  topbar.hide();
});

// connect if there are any LiveViews on the page
liveSocket.connect();

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket;

var events = ['email-updated', 'confirmation-required', 'data-fetched'];

const effectEvent = evt => {
  document.querySelectorAll('[js-trigger-' + evt + ']').forEach(el => {
    liveSocket.execJS(el, el.getAttribute('js-action-' + evt));
  });
};

events.forEach(evt => {
  window.addEventListener('phx:' + evt, e => effectEvent(evt));
});

window.addEventListener('phx:close-roster', () => {
  document.querySelectorAll('[x-bind="rosterAutoClose"]').forEach(el => {
    e = new Event('close-roster');
    el.dispatchEvent(e);
  });
});

var timeoutId = undefined;
const spinnerTimeoutMs = 5000;

window.addEventListener('phx:show-spinner', event => {
  let timeoutMS = spinnerTimeoutMs;

  if (event.detail.timeout) {
    timeoutMS = event.detail.timeout;
  }

  timeoutId = setTimeout(() => {
    window.dispatchEvent(new Event('phx:close-spinner'));
  }, timeoutMS);
  effectEvent('show-spinner');
});

window.addEventListener('phx:close-spinner', () => {
  if (timeoutId) clearTimeout(timeoutId);
  timeoutId = undefined;
  effectEvent('close-spinner');
});

hooks.ScrollToTop = {
  mounted() {
    this.el.addEventListener('click', e => {
      window.scrollTo(0, 0);
    });
  }
};

hooks.CopyLink = {
  mounted() {
    this.el.addEventListener('click', () => {
      this.el.classList.add("btn--secondary");
      this.el.innerHTML = 'Copied!';
      // After 2 seconds, change back
      setTimeout(() => {
        this.el.classList.remove("btn--secondary");
        this.el.innerHTML = 'Copy Link';
      }, 1000);
    });
  }
};

hooks.Countdown = {
  mounted() {
    this.timer = setCountdown(this);
  },
  beforeUpdate() {
    clearInterval(this.timer);
  },
  updated() {
    this.timer = setCountdown(this);
  },
  destroyed() {
    clearInterval(this.timer);
  }
};
