export default () => {
  const clickAndGrabScroll = {
    mounted() {
      const foo = document.querySelector('.items');
      let isDown = false;
      let startX;
      let scrollLeft;

      foo.addEventListener('mousedown', e => {
        isDown = true;
        foo.classList.add('active');
        startX = e.pageX - foo.offsetLeft;
        scrollLeft = foo.scrollLeft;
      });

      foo.addEventListener('mouseleave', () => {
        isDown = false;
        foo.classList.remove('active');
      });

      foo.addEventListener('mouseup', () => {
        isDown = false;
        foo.classList.remove('active');
      });

      foo.addEventListener('mousemove', e => {
        if (!isDown) return;
        e.preventDefault();
        const x = e.pageX - foo.offsetLeft;
        const walk = (x - startX) * 3; //scroll-fast
        foo.scrollLeft = scrollLeft - walk;
      });
    }
  };
  return { hooks: { clickAndGrabScroll } };
};
