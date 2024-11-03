// https://stackoverflow.com/questions/179355/clearing-all-cookies-with-javascript

export default () => {
  const clearCookies = () => {
    var cookies = document.cookie.split('; ');
    if (cookies.length == 0) {
      console.log('Nothing to do');
    } else {
      console.log('clearing ' + cookies.length + ' cookies!');
      for (var c = 0; c < cookies.length; c++) {
        var d = window.location.hostname.split('.');
        while (d.length > 0) {
          var cookieBase =
            encodeURIComponent(cookies[c].split(';')[0].split('=')[0]) +
            '=; expires=Thu, 01-Jan-1970 00:00:01 GMT; domain=' +
            d.join('.') +
            ' ;path=';
          var p = location.pathname.split('/');
          document.cookie = cookieBase + '/';
          while (p.length > 0) {
            document.cookie = cookieBase + p.join('/');
            p.pop();
          }
          d.shift();
        }
      }
    }
  };
  return { clearCookies };
};
