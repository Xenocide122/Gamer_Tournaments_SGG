const colors = require('tailwindcss/colors');

module.exports = {
  mode: 'jit',
  content: ['./js/**/*.js', '../lib/*_web/**/*.*ex'],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        primary: 'var(--color-primary)',
        'primary-dark': 'var(--color-primary-dark)',
        secondary: 'var(--color-secondary)',
        'secondary-dark': 'var(--color-secondary-dark)',
        'strident-black': '#01060F',
        'grilla-pink': '#FF6802',
        'grilla-blue': '#03D5FB',
        'grilla-gold': '#F1C243',
        'grilla-silver': '#ADB7BF',
        'grilla-bronze': '#C1762B',
        transparent: 'transparent',
        blackish: '#000d1f',
        greyish: '#072034',
        grey: {
          DEFAULT: '#262626',
          dark: '#171717',
          medium: '#262626',
          light: '#a3a3a3'
        },
        'brands-twitch': 'var(--brands-twitch)',
        'brands-discord': 'var(--brands-discord)'
      },
      dropShadow: {
        '3xl': '1px 1px 25px #03d5fb',
      },
      fontFamily: {
        sans: ['PTSans', 'sans-serif'],
        display: ['Rajdhani', 'sans-serif']
      },
      gridTemplateColumns: {
        16: 'repeat(16, minmax(0, 1fr))',
        21: 'repeat(21, minmax(0, 1fr))'
      },
      gridColumn: {
        'span-15': 'span 15 / span 15'
      },
      height: {
        '100': '25rem',
        '104': '26rem',
        '108': '27rem',
        '112': '28rem',
        '116': '29rem',
        '120': '30rem',
        '124': '31rem',
        '128': '32rem'
      },
      minHeight: {
        auto: 'auto'
      },
      spacing: {
        128: '32rem',
        144: '36rem'
      },
      boxShadow: {
        primary: '0px 0px 10px rgba(17, 235, 133, 1)',
        'grilla-pink': '0px 0px 10px rgba(210, 80, 209, 1)',
        'grilla-gold': '0px 0px 10px rgba(241, 195, 67, 1)',
        'grilla-silver': '0px 0px 10px rgba(173, 183, 191, 1)',
        'grilla-bronze': '0px 0px 10px rgba(193, 118, 43, 1)',
        'grilla-two-colors-pink': '0px 0px 20px rgba(210, 80, 209, 1)',
        'grilla-two-colors-blue': '0px 0px 30px #ff6802',
        'grilla-turnament-shadow':
          '58px 58px 30px -58px rgba(258,80,209,1), -58px -58px 30px -58px #ff6802, 58px -58px 30px -58px rgba(258,80,209,1), -58px 58px 30px -58px #ff6802'
      },
      screens: {
        xs: '370px',
        '3xl': '1600px'
      },
      scale: {
        80: '.80',
        60: '.60'
      },
      keyframes: {
        shine: {
          '0%': { left: '-50%' },
          '10%': { left: '150%' },
          '100%': { left: '150%' }
        }
      },
      animation: {
        shine: 'shine 6s ease-in-out infinite'
      },
      textUnderlineOffset: {
        32: '32px',
      },
      width: {
        81: '21rem'
      }
    }
  },
  variants: {
    extend: {}
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/line-clamp'),
    require('@thoughtbot/tailwindcss-aria-attributes'),
    require('tailwindcss-animate')
  ]
};
