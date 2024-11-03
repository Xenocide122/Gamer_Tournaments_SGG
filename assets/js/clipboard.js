window.addEventListener('grilla:clipcopy', event => {
  copyToClipboard(event.target.textContent);
});

window.addEventListener('grilla:clipcopyinput', event => {
  copyToClipboard(event.target.value);
});

function copyToClipboard(text) {
  console.log(text);
  if ('clipboard' in navigator) {
    navigator.clipboard.writeText(text);
  } else {
    alert('Sorry, your browser does not support clipboard copy.');
  }
}
