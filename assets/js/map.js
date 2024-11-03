export default {
  mounted() {
    const pushEventToLiveView = (event, payload) => {
      this.pushEvent(event, payload);
    };
    const pushEventToComponent = (event, payload) => {
      this.pushEventTo(this.el, event, payload);
    };
    const pushEvent = (event, payload) => {
      if (!!this.el.dataset.pushToComponent) {
        pushEventToComponent(event, payload);
      } else {
        pushEventToLiveView(event, payload);
      }
    };

    let autocomplete;
    let map;
    let zoomLevel = 15;
    let mapMarkers = [];

    function clearMarkers() {
      for (let i = 0; i < mapMarkers.length; i++) {
        mapMarkers[i].setMap(null);
      }
    }

    function drawMarkers() {
      for (let i = 0; i < mapMarkers.length; i++) {
        mapMarkers[i].setMap(map);
      }
    }

    function initMap() {
      let map_element = document.getElementById('map');
      let lat = map_element.dataset.lat;
      let lng = map_element.dataset.lng;

      if (lat && lng) {
        map = new google.maps.Map(map_element, {
          center: {
            lat: parseFloat(lat),
            lng: parseFloat(lng)
          },
          zoom: zoomLevel
        });

        mapMarkers.push(
          new google.maps.Marker({
            position: { lat: parseFloat(lat), lng: parseFloat(lng) },
            map
          })
        );
        drawMarkers();
      } else {
        map = new google.maps.Map(map_element, {
          center: { lat: 25.7895342, lng: -80.14778650000001 },
          zoom: zoomLevel
        });
      }
    }

    initMap();

    function onPlaceChanged() {
      var place = autocomplete.getPlace();

      let lat = place.geometry.location.lat();
      let lng = place.geometry.location.lng();

      pushEvent('set_lat_lng', {
        lat: lat,
        lng: lng,
        full_address: place.formatted_address
      });

      clearMarkers();
      mapMarkers.push(
        new google.maps.Marker({
          position: { lat: lat, lng: lng },
          map
        })
      );

      map.panTo({ lat: lat, lng: lng });
    }

    if (document.getElementById('places-autocomplete')) {
      autocomplete = new google.maps.places.Autocomplete(
        document.getElementById('places-autocomplete'),
        {
          types: ['address'],
          fields: ['place_id', 'geometry.location', 'name', 'formatted_address']
        }
      );

      autocomplete.addListener('place_changed', onPlaceChanged);
    }
  }
};
