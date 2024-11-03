import flatpickr from 'flatpickr';
import { DateTime as DT } from 'luxon';

export default () => {
  const Flatpickr = {
    mounted() {
      const browserTimezone = new Intl.DateTimeFormat('en-US', {
        timeZoneName: 'shortOffset'
      })
        .format(new Date())
        .match(/.*,(.*)/)[1]
        .trim()
        .replace('GMT', 'UTC');

      const browserTimezoneOffsetSeconds =
        Number.parseInt(browserTimezone.replace('UTC', '') || '0') * 3600;

      const timezoneOffsetSeconds = Number.parseInt(
        this.el.dataset.timezone_offset_seconds
      );

      const timezone = this.el.dataset.timezone || browserTimezone;

      const initialRenderDateFormat = "yyyy-MM-dd'T'HH:mm:ss'";
      const hasAttrReturnDate = this.el.hasAttribute('returndate');
      const hasAttrNoTime = this.el.hasAttribute('notime');
      const dateFormat = hasAttrReturnDate
        ? 'Y-m-d'
        : hasAttrNoTime
        ? 'Z'
        : "yyyy-MM-dd'T'HH:mm:ss'Z'";
      const altInputZonedFormat = 'd LLL yyyy, HH:mm';
      const altInputZonedFormatNoTime = 'Y-m-d';
      const browserFormat = `d MMM yyyy, HH:mm' (${timezone})'`;
      const browserFormatNoTime = `d MMM yyyy'`;

      const DateTime = DT;

      const hasAttrMode = this.el.hasAttribute('mode');
      const mode = hasAttrMode ? this.el.getAttribute('mode') : 'single';

      const formatDateFxn = (date, format) => {
        const someFormat = hasAttrNoTime
          ? altInputZonedFormatNoTime
          : altInputZonedFormat;

        const someDate = DateTime.fromJSDate(date).setZone(timezone, {
          keepLocalTime: true
        });
        if (format == someFormat) {
          if (hasAttrNoTime) {
            return someDate.toFormat(someFormat);
          } else {
            const altInputDateTime = someDate.toFormat(altInputZonedFormat);
            return `${altInputDateTime} (${timezone})`;
          }
        } else {
          return someDate.setZone('UTC').toFormat(format);
        }
      };
      let flatpickrOpts = {
        altInput: true,
        altFormat: hasAttrNoTime
          ? altInputZonedFormatNoTime
          : altInputZonedFormat,
        enableTime: !hasAttrNoTime,
        mode: mode,
        inline: this.el.hasAttribute('inline'),
        time_24hr: true,
        disableMobile: 'true',
        // Using the Luxon codes, not flatpickr codes.
        // https://moment.github.io/luxon/index.html#/formatting?id=macro-tokens
        dateFormat: dateFormat,
        // showMonths: hasAttrNoTime ? 1 : 2,
        showMonths: 1,
        allowInput: hasAttrNoTime ? false : true,
        parseDate: hasAttrReturnDate
          ? false
          : (dateString, format) => {
              if (hasAttrNoTime) {
                dateString += dateString.match(/^.*[a-z]+$/i) ? '' : 'Z';
                return new Date(dateString);
              } else {
                let date = DT.fromFormat(dateString, initialRenderDateFormat, {
                  zone: 'UTC'
                });
                const isInitialRendering = !date.invalid;

                if (isInitialRendering) {
                  // must be initial rendering - put the timezone on the date with shifting/projecting
                  date = date.setZone(timezone);
                } else {
                  // must be a non-initial rendering - put the timezone on the date without shifting/projecting
                  date = DT.fromFormat(
                    dateString,
                    hasAttrNoTime ? browserFormatNoTime : browserFormat
                  ).setZone(browserTimezone);
                }

                const contemporaryBrowserTimezone = new Intl.DateTimeFormat(
                  'en-US',
                  {
                    timeZoneName: 'shortOffset'
                  }
                )
                  .format(date)
                  .match(/.*,(.*)/)[1]
                  .trim()
                  .replace('GMT', 'UTC');

                contemporaryBrowserTimezoneOffsetSeconds =
                  Number.parseInt(
                    contemporaryBrowserTimezone.replace('UTC', '') || '0'
                  ) * 3600;

                const localJsDate = date.toUTC().toJSDate();

                if (isInitialRendering) {
                  const utcJsDate = new Date(
                    date.toSeconds() * 1000 +
                      (timezoneOffsetSeconds -
                        contemporaryBrowserTimezoneOffsetSeconds) *
                        1000
                  );
                  return utcJsDate;
                } else {
                  return localJsDate;
                }
              }
            }
      };

      if (!hasAttrNoTime) {
        flatpickrOpts.formatDate = (date, format) =>
          formatDateFxn(date, format);
      }

      flatpickr(`#${this.el.id}`, flatpickrOpts);
    }
  };

  return { hooks: { Flatpickr } };
};
