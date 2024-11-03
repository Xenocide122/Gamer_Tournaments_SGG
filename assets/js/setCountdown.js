function msToTime(duration) {
  var seconds = Math.floor((duration / 1000) % 60),
    minutes = Math.floor((duration / (1000 * 60)) % 60),
    hours = Math.floor((duration / (1000 * 60 * 60)) % 24),
    days = Math.floor(duration / (1000 * 60 * 60 * 24));

  hours = hours < 10 ? '0' + hours : hours;
  minutes = minutes < 10 ? '0' + minutes : minutes;
  seconds = seconds < 10 ? '0' + seconds : seconds;

  return days > 0
    ? days + 'd : ' + hours + 'h : ' + minutes + 'm : ' + seconds + 's'
    : hours + 'h : ' + minutes + 'm : ' + seconds + 's';
}

function setCountdown(hook) {
  var timerEnd = hook.el.dataset.end_date;

  var countdownDate = new Date(timerEnd).getTime();

  var interval = setInterval(function () {
    var now = new Date().getTime();

    var distance = countdownDate - now;

    document.getElementById(hook.el.id).innerHTML = msToTime(distance);

    if (distance < 0) {
      clearInterval(interval);
      document.getElementById(hook.el.id).innerHTML = 'Time Has Expired';
    }
  }, 1000);

  return interval;
}

export default setCountdown;
