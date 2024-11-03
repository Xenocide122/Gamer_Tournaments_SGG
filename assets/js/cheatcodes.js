// https://stackoverflow.com/a/71309611

import prepareKonamiCanvas from './konami-canvas';
import prepareCookies from './cookies';

const konamiCanvas = prepareKonamiCanvas();
const cookies = prepareCookies();

export default () => {
  var cheats = [];

  const registerKeyCodes = ({ konami, clear_cookies }) => {
    cheats = [
      {
        keyCodes: konami,
        event: 'start_cheat_konami',
        inputPositions: []
      },
      {
        keyCodes: clear_cookies,
        event: 'clear_cookies',
        inputPositions: []
      }
    ];
  };

  const Cheatcodes = {
    mounted() {
      const pushEventToComponent = (event, payload) => {
        this.pushEventTo(this.el, event, payload);
      };

      this.handleEvent(
        'psst_here_are_the_cheatcodes',
        ({ key_codes: key_codes }) => registerKeyCodes(key_codes)
      );
      this.handleEvent('stop_cheat_konami', () => konamiCanvas.clear());
      this.handleEvent('stop_cheat_konami', () => konamiCanvas.clear());
      this.handleEvent('clear_cookies', () => cookies.clearCookies());

      const incrementOrRemove = (
        keyCode,
        { keyCodes, event, payload, inputPositions }
      ) => {
        return inputPositions.reduce((acc, inputPosition, i, arr) => {
          if (keyCode == keyCodes[inputPosition]) {
            inputPosition++;
            if (inputPosition == keyCodes.length) {
              inputPositions = [];
              pushEventToComponent(event, payload || {});
              arr.splice(1); // eject early by mutating iterated copy
              return [];
            } else {
              acc.push(inputPosition);
              return acc;
            }
          } else {
            return acc;
          }
        }, []);
      };

      const handleKeyDownEvent = event => {
        const { keyCode } = event;
        cheats.map(cheat => {
          if (keyCode == cheat.keyCodes[0]) cheat.inputPositions.push(0);
          if (cheat.inputPositions.length > 0)
            cheat.inputPositions = incrementOrRemove(keyCode, cheat);
        });
      };

      document.addEventListener('keydown', event => handleKeyDownEvent(event));
    }
  };

  return { hooks: { Cheatcodes } };
};
