export default () => {
  const QrCode = {
    mounted() {
      if (this.el.dataset.pageLink) {
        var qrcode = new QRCode(this.el, {
          text: this.el.dataset.pageLink,
          width: 128,
          height: 128,
          colorDark: '#000000',
          colorLight: '#03d5fb',
          correctLevel: QRCode.CorrectLevel.H
        });
      }
    }
  };

  return { hooks: { QrCode } };
};
