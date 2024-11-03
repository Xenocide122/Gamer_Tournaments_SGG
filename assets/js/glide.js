import GlideObject from '@glidejs/glide';

export default () => {
  const Glide = {
    mounted() {
      this.glide = new GlideObject(`#${this.el.id}`, {
        type: 'carousel',
        focusAt: 'center',
        autoplay: 4000,
        animationDuration: 150,
        gap: 16,
        startAt: 0,
        perView: 3,
        peek: 140,
        breakpoints: {
          1000: {
            perView: 2,
            peek: 80
          },
          768: {
            perView: 1,
            peek: 0
          },
          640: {
            perView: 1,
            peek: 60
          }
        }
      });

      this.glide.mount();
    }
  };

  return { hooks: { Glide } };
};
