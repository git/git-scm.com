// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery-1.7.1.min
//= require jquery-ui-1.8.18.custom.min
//= require jquery.defaultvalue
//= require session.min

// Used to detect initial (useless) popstate.
// If history.state exists, assume browser isn't going to fire initial popstate.
popped = 'state' in window.history;
initialURL = location.href;

$(document).ready(function() {
  BrowserFallbacks.init();
  Search.init();
  Dropdowns.init();
  Forms.init();
  Downloads.init();
  DownloadBox.init();
});

function onPopState(fn) {
  if (window.history && window.history.pushState) {
    return $(window).bind('popstate', function(event) {
      var section;
      initialPop = !popped && location.href === initialURL;
      popped = true;
      if (initialPop) {
        return;
      }
      fn();
    });
  }
}

var DownloadBox = {
  init: function() {
    $('#gui-os-filter').addClass('visible');
    var os = window.session.browser.os; // Mac, Win, Linux
    if(os == "Mac") {
      $(".monitor").addClass("mac");
      $("#download-link").text("Download for Mac").attr("href", "/download/mac");
      $("#gui-link").removeClass('mac').addClass('gui');
      $("#gui-link").text("Mac GUIs").attr("href", "/download/gui/mac");
      $("#gui-os-filter").attr('data-os', 'mac');
      $("#gui-os-filter").text("Only show GUIs for my OS (Mac)")
    } else if (os == "Windows") {
      $(".monitor").addClass("windows");
      $("#download-link").text("Download for Windows").attr("href", "/download/win");
      $("#gui-link").removeClass('mac').addClass('gui');
      $("#gui-link").text("Windows GUIs").attr("href", "/download/gui/windows");
      $("#alt-link").removeClass("windows").addClass("mac");
      $("#alt-link").text("Mac Build").attr("href", "/download/mac");
      $("#gui-os-filter").attr('data-os', 'windows');
      $("#gui-os-filter").text("Only show GUIs for my OS (Windows)")
    } else if (os == "Linux") {
      $(".monitor").addClass("linux");
      $("#download-link").text("Download for Linux").attr("href", "/download/linux");
      $("#gui-link").removeClass('mac').addClass('gui');
      $("#gui-link").text("Linux GUIs").attr("href", "/download/gui/linux");
      $("#alt-link").removeClass("windows").addClass("mac");
      $("#alt-link").text("Mac Build").attr("href", "/download/mac");
      $("#gui-os-filter").attr('data-os', 'linux');
      $("#gui-os-filter").text("Only show GUIs for my OS (Linux)")
    } else {
    }
  }
}

var BrowserFallbacks = {
  init: function() {
    BrowserFallbacks.initPlaceholders();
  },

  initPlaceholders: function() {
    if (!Modernizr.input.placeholder) {
      $('input[placeholder], textarea[placeholder]').each(function(input) {
        $(this).defaultValue($(this).attr('placeholder'), 'active', 'inactive');
      });
    }
  }

}

var Search = {
  searching: false,
  currentSearch: '',
  selectedIndex: 0,

  init: function() {
    Search.observeFocus();
    Search.observeTextEntry();
    Search.observeResultsClicks();
  },

  observeFocus: function() {
    $('form#search input').focus(function() {
      $(this).parent('form#search').switchClass("", "focus", 200);
    });
    $('form#search input').blur(function() {
      Search.resetForm();
    });
  },

  observeTextEntry: function() {
    $('form#search input').keyup(function(e) {
      Search.runSearch();
    });

    $('form#search input').keydown(function(e) {
      if ($('#search-results').not(':visible') && e.which != 27) {
        $('#search-results').fadeIn(0.2);
        Search.highlight(Search.selectedIndex);
      }
      switch(e.which) {
        case 13: // enter
          Search.selectResultOption();
          return false;
          break;
        case 27: // esc
          Search.resetForm();
          break;
        case 38: // up
          e.preventDefault();
          Search.resultsNav("up");
          break;
        case 40: // down
          e.preventDefault();
          Search.resultsNav("down");
          break;
      };
    });
  },

  observeResultsClicks: function() {
    $('#search-results').mousedown(function(e) {
      e.preventDefault();
    });
  },

  runSearch: function() {
    var term = $('#search-text').val();
    if(term.length < 2) { return false };

    if(!Search.searching) {
      Search.searching = true;

      if(term != Search.currentSearch) {
        Search.currentSearch = term;
        $.get("/search", {search: term}, function(results) {
          $("#search-results").html(results);
          Search.searching = false;
        }, 'html');
      };
    }
    else {
      clearTimeout(Search.timeout);
      Search.timeout = setTimeout(function() {
        Search.searching = false;
        Search.runSearch();
      }, 300);
    }
  },

  selectResultOption: function() {
    var link = $('#search-results a')[Search.selectedIndex];
    var url = $(link).attr('href');
    if(!url) {
      var term = $('#search-text').val();
      url = "/search/results?search=" + term;
    }
    window.location.href = url;
    selectedIndex = 0;
  },

  resultsNav: function(direction) {
    Search.selectedIndex += (direction == "down") ? 1 : -1;
    Search.highlight(Search.selectedIndex);
  },

  highlight: function(index) {
    var links = $('#search-results a').removeClass('highlight');
    $(links[index]).addClass('highlight');
  },

  resetForm: function() {
    $('form#search').switchClass("focus", "", 200);
    $('#search-results').fadeOut(0.2);
    Search.selectedIndex = 0;
  }
}

var Dropdowns = {
  init: function() {
    Dropdowns.observeTriggers();
  },

  observeTriggers: function() {
    var eles = $('.dropdown-trigger');
    eles.click(function(e) {
      e.preventDefault();
      
      $(this).toggleClass('active');
      $('#' + $(this).attr('data-panel-id')).toggle();
      
      eles.each((_, ele)=>{
        if(ele === this) return
        $(ele).removeClass('active');
        $('#' + $(ele).attr('data-panel-id')).hide();
      })
    });
  }
}

var Forms = {
  init: function() {
    Forms.observeCopyableInputs();
  },

  observeCopyableInputs: function() {
    $('input.copyable').click(function() {
      $(this).select();
    });
  }
}
var Downloads = {
  init: function() {
    Downloads.observeGUIOSFilter();
    Downloads.observePopState();
    Downloads.filterGUIS();
  },

  getOSFilter: function() {
    var os = location.href.substring(location.href.lastIndexOf("/") + 1);
    return os === 'linux' || os === 'mac' || os === 'windows' || os === 'android' || os === 'ios' ? os : '';
  },

  capitalizeOS: function(os) {
    const platforms = {"linux": "Linux", "mac": "Mac", "windows": "Windows", "android": "Android", "ios": "iOS"};
    return platforms[os];
  },

  filterGUIS: function() {
    var osFilter = Downloads.getOSFilter();
    var capitalizedOS = Downloads.capitalizeOS(osFilter);
    $('a.gui-os-filter').not("[data-os='"+osFilter+"']").removeClass('selected');
    $('a.gui-os-filter').filter("[data-os='"+osFilter+"']").addClass('selected');

    if (osFilter === '') {
      $('ul.gui-thumbnails li').removeClass("masked");
      $('#os-filter-count').hide();
    }
    else {
      $('ul.gui-thumbnails li').filter("."+osFilter).removeClass('masked');
      $('ul.gui-thumbnails li').not("."+osFilter).addClass('masked');
      var osCount = $('ul.gui-thumbnails li' + '.' + osFilter).length;
      $('#os-filter-count strong').html(osCount);
      $('#os-filter-count .os').html(capitalizedOS);
      $('#os-filter-count').show();
    }
  },

  observeGUIOSFilter: function() {
    $('a.gui-os-filter').click(function(e) {
      e.preventDefault();
      var os = $(this).attr('data-os');

      if (window.history && window.history.pushState) {
        var url = os === ''
          ? '/downloads/guis/'
          : '/download/gui/'+os;
        history.pushState(null, $(this).html(), url);
      }

      Downloads.filterGUIS();
    });
  },

  observePopState: function() {
    onPopState(function() {
      Downloads.filterGUIS();
    });
  }
}

// Scroll to Top
$('#scrollToTop').removeClass('no-js');
$(window).scroll(function() {
  $(this).scrollTop() > 150
    ? $('#scrollToTop').fadeIn()
    : $('#scrollToTop').fadeOut();
});
$('#scrollToTop').click(function(e) {
  e.preventDefault();
  $("html, body").animate({
      scrollTop: 0
  }, "slow");
  return false;
});
