var matrixIntervalId = undefined;
export default () => {
  const clear = ev => {
    var canvas = document.getElementById('konami-canvas');
    matrixIntervalId && clearInterval(matrixIntervalId);
  };

  const draw = ev => {
    var canvas = document.getElementById('konami-canvas');
    var ctx = canvas.getContext('2d');
    var t = text();
    var lines = [];
    function drawLines() {
      if (lines.length < 100) {
        if (Math.floor(Math.random() * 2) === 0) {
          lines.push(new textLine());
        }
      }
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      lines.forEach(function (tl) {
        ctx.drawImage(tl.text, tl.posX, tl.animate(), 20, 1000);
      });
    }

    function textLine() {
      this.text = t;
      this.posX = (function () {
        return Math.floor(Math.random() * canvas.width);
      })();
      this.offsetY = -1000;
      this.animate = function () {
        if (this.offsetY >= 0) {
          this.offsetY = -1000;
        }
        this.offsetY += 10;
        return this.offsetY;
      };
    }

    function text() {
      var offscreenCanvas = document.createElement('canvas');
      offscreenCanvas.width = '30';
      offscreenCanvas.height = '1000';
      offscreenCanvas.style.display = 'none';
      document.body.appendChild(offscreenCanvas);
      var octx = offscreenCanvas.getContext('2d');
      octx.textAlign = 'center';
      octx.shadowColor = 'lightgreen';
      octx.shadowOffsetX = 2;
      octx.shadowOffsetY = -5;
      octx.shadowBlur = 1;
      octx.fillStyle = 'darkgreen';
      octx.textAlign = 'left';
      var step = 10;
      for (i = 0; i < 100; i++) {
        var charCode = 0;
        while (charCode < 60) {
          charCode = Math.floor(Math.random() * 100);
        }
        octx.fillText(String.fromCharCode(charCode), 0, step);
        step += 10;
      }
      return offscreenCanvas;
    }

    matrixIntervalId = window.setInterval(drawLines, 100);
  };

  return { draw, clear };
};
