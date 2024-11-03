export default () => {
  const TwitchEmbed = {
    mounted() {
      if (this.el.dataset.channelName) {
        embedHeight = 480;
        embedWidth = 0;

        if (window.innerWidth < 640) {
          embedWidth = '100%';
        } else {
          embedWidth = 854;
        }
        if (this.el.dataset.showClientFullScreen) {
          embedWidth = document.body.clientWidth;
          embedHeight = embedWidth * (9 / 16);
        }

        layout = 'video-with-chat';
        if (this.el.dataset.showLayout) {
          layout = this.el.dataset.showLayout;
        }

        new Twitch.Embed('twitch-embed', {
          width: this.el.dataset.width || embedWidth,
          height: this.el.dataset.height || embedHeight,
          channel: this.el.dataset.channelName,
          theme: 'dark',
          layout: layout
        });
      }
    }
  };

  return { hooks: { TwitchEmbed } };
};
