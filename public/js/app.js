$.extend({
  getUrlVars: function(){
    var queryParameters = {}
    var queryString = location.search.substring(1)
    var re = /([^&=]+)=([^&]*)/g
    var m;

    while (m = re.exec(queryString)) {
        queryParameters[decodeURIComponent(m[1])] = decodeURIComponent(m[2]);
    }

    return queryParameters;
  },
  getUrlVar: function(name){
    return $.getUrlVars()[name];
  },
  setUrlVar: function(name, value){
    var queryParameters = $.getUrlVars();
    queryParameters[name] = value;
    window.history.pushState('page2', 'Title', '/?'+$.param(queryParameters));
  }
});


$(document).ready(function(){
  soundManager.url = '/swf/';
  soundManager.waitForWindowLoad = true;
  soundManager.debugMode = false;
  soundManager.flashVersion = 9;
  soundId = 0;
  
  soundManager.ontimeout(function(status) {
    alert('SM2 failed to start. Flash missing, blocked or security error?');
    alert('The status is ' + status.success + ', the error type is ' + status.error.type);
  });
  
  soundManager.onready(function(){
    var currentSong = null;
        
    var playSong = function(id, autoplay) {
      $.setUrlVar('id', id);
      $.ajax({
        url: "/api/song_info?id="+escape(id),
        dataType: 'json',
        success: function(data, textStatus, jqXHR) {
          artist = data['artist']['name'];
          title = data['song']['name'];
          $('.text').text(artist+' - '+title);
          $(document).attr("title", artist+' - '+title);
        },
      });
      
      if(currentSong) {
        currentSong.destruct();
      }
      
      currentSong = soundManager.createSound({
        id: 'sound'+id,
        url: '/audio/get?id='+escape(id),
        autoLoad: true,
        autoPlay: false,
        volume: 100,
        onfinish: function() {
          next();
        },
        whileloading: function() {
          $("#progressbar").slider('values', 0, (this.position / this.durationEstimate)*100);
          $("#progressbar").slider('values', 1, (this.duration / this.durationEstimate)*100);
        },
        whileplaying: function() {
          if(this.readyState == 3) {
            $("#progressbar").slider('values', 0, (this.position / this.duration)*100);
            $("#progressbar").slider('values', 1, 100);
          }
        }
      });

      if(autoplay) {
        currentSong.play();
        $('.pause').text("Pause");
      }
    }
    
    var next = function() {
      $.ajax({
        url: "/api/next",
        dataType: 'json',
        success: function(data, textStatus, jqXHR) {
          song = data['song'];
          playSong(song['id'], true);
          updateQueue();
        },
      });
    };

    var loadArtists = function() {
      $.ajax({
        url: "/api/artists",
        dataType: 'json',
        success: function(data, textStatus, jqXHR) {
          $('.listview').html('');
          
          artists = data['artists'];
          $.each(artists, function(i, artist) {
            var artist = artist['artist'];
            $("<li/>", {
              "class": "artist",
              text: artist['name'],
              click: function(){
                loadAlbums(artist['id']);
              }
            }).appendTo($('.listview'));
          });
        },
      });
    };

    var loadAlbums = function(artist) {
      $.ajax({
        url: "/api/albums?artist="+escape(artist),
        dataType: 'json',
        success: function(data, textStatus, jqXHR) {
          $('.listview').html('');
          
          $("<li/>", {
            "class": "back",
            text: "Back",
            click: function() {
              loadArtists();
            }
          }).appendTo($('.listview'));
          
          $("<li/>", {
            "class": "all",
            text: "Show All",
            click: function() {
              loadSongs(artist, null);
            }
          }).appendTo($('.listview'));
          
          albums = data['albums'];
          $.each(albums, function(i, album) {
            var album_ = album['album'];
            var artist_ = album['artist'];
            $("<li/>", {
              "class": "album",
              text: album_['name'],
              click: function() {
                loadSongs(artist_['id'], album_['id']);
              }
            }).appendTo($('.listview'));
          });
        },
      });
    };

    var loadSongs = function(artist, album) {
      $.ajax({
        url: "/api/songs?"+(artist ? "&artist="+escape(artist) : '')+(album ? "&album="+escape(album) : ''),
        dataType: 'json',
        success: function(data, textStatus, jqXHR) {
          $('.listview').html('');
          
          $("<li/>", {
            "class": "back",
            text: "Back",
            click: function() {
              loadAlbums(artist);
            }
          }).appendTo($('.listview'));
          
          songs = data['songs'];
          $.each(songs, function(i, song) {
            var song_ = song['song'];
            var album_ = song['album'];
            var artist_ = song['artist'];
            $("<li/>", {
              "class": "song",
              text: song_['name'],
              click: function() {
                queueSong(song_['id']);
              }
            }).appendTo($('.listview'));
          });
        },
      });
    };

    var queueSong = function(id) {
      $.ajax({
        url: "/api/add_song?id="+escape(id),
        dataType: 'json',
        success: function(data, textStatus, jqXHR) {
          updateQueue();
        },
      });
    };

    var removeSong = function(id) {
      $.ajax({
        url: "/api/remove?id="+escape(id),
        dataType: 'json',
        success: function(data, textStatus, jqXHR) {
          updateQueue();
        },
      });
    }

    var updateQueue = function() {
      $.ajax({
        url: "/api/queue",
        dataType: 'json',
        success: function(data, textStatus, jqXHR) {
          $('.queue').html('');
          songs = data['songs'];
          $.each(songs, function(i, song) {
            $("<li/>", {
              "class": "queued-song",
              text: song['artist']['name']+' - '+song['song']['name'],
              click: function() {
                removeSong(song['queue_id']);
              }
            }).appendTo($('.queue'));
          });
        },
      });
    };

    if($.getUrlVar('id')) {
      playSong($.getUrlVar('id'), true);
    } else {
      $.ajax({
        url: "/api/playing",
        dataType: 'json',
        success: function(data, textStatus, jqXHR) {
          song = data['song'];
          playSong(song['id'], false);
        },
      });
    }
    
    $('.next').click(function(e){
      next();
    });
    
    $('.pause').click(function(e){
      if(currentSong.playState == 0) {
        currentSong.play();
        return;
      }
      if(currentSong.paused) {
        currentSong.play();
        $(this).text("Pause");
      } else {
        currentSong.pause();
        $(this).text("Play");
      }
    });
    
    $("#progressbar").slider({
      animate: true,
      range: true,
      values: [0, 0],
      slide: function(e, ui) {
        if(currentSong.readyState == 1) {
          currentSong.setPosition((ui.value/100) * currentSong.durationEstimate);
        } else if(currentSong.readyState == 3) {
          currentSong.setPosition((ui.value/100) * currentSong.duration);
        }
      }
    });
    
    loadArtists();
    updateQueue();
    var updater = setInterval(function() {
      updateQueue();
    }, 2000);
  });
});

