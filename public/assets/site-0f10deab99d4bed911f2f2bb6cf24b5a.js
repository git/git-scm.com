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
  AboutContent.init();
  FlippyBook.init();

  var _gauges = _gauges || [];
  (function() {
    var t   = document.createElement('script');
    t.type  = 'text/javascript';
    t.async = true;
    t.id    = 'gauges-tracker';
    t.setAttribute('data-site-id', '4f919d1df5a1f504b3000026');
    t.src = '//secure.gaug.es/track.js';
    var s = document.getElementsByTagName('script')[0];
    s.parentNode.insertBefore(t, s);
  })();
});

var DownloadBox = {
  init: function() {
    $('#gui-os-filter').addClass('visible');
    var os = window.session.browser.os; // Mac, Win, Linux
    if(os == "Mac") {
      $(".monitor").addClass("mac");
      $("#download-link").text("Downloads for Mac").attr("href", "/download/mac");
      $("#gui-link").removeClass('mac').addClass('gui');
      $("#gui-link").text("Mac GUIs").attr("href", "/download/gui/mac");
      $("#gui-os-filter").attr('data-os', 'mac');
      $("#gui-os-filter").text("Only show GUIs for my OS (Mac)")
    } else if (os == "Windows") {
      $(".monitor").addClass("windows");
      $("#download-link").text("Downloads for Windows").attr("href", "/download/win");
      $("#gui-link").removeClass('mac').addClass('gui');
      $("#gui-link").text("Windows GUIs").attr("href", "/download/gui/win");
      $("#alt-link").removeClass("windows").addClass("mac");
      $("#alt-link").text("Mac Build").attr("href", "/download/mac");
      $("#gui-os-filter").attr('data-os', 'windows');
      $("#gui-os-filter").text("Only show GUIs for my OS (Windows)")
    } else if (os == "Linux") {
      $(".monitor").addClass("linux");
      $("#download-link").text("Downloads for Linux").attr("href", "/download/linux");
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
    if(!link) {
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
    $('.dropdown-trigger').click(function(e) {
      e.preventDefault();
      var panelId = $(this).attr('data-panel-id');
      if ($(this).hasClass('active')) {
        $(this).removeClass('active');
        $('#'+panelId).hide();
      }
      else {
        $(this).addClass('active');
        $('#'+panelId).show();
      }
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
  userOS: '',

  init: function() {
    Downloads.observeGUIOSFilter();
  },

  observeGUIOSFilter: function() {
    $('a#gui-os-filter').click(function(e) {
      e.preventDefault();
      Downloads.userOS = $(this).attr('data-os');
      var capitalizedOS = Downloads.userOS.charAt(0).toUpperCase() + Downloads.userOS.slice(1);
      if ($(this).hasClass('filtering')) {
        $('ul.gui-thumbnails li').switchClass("masked", "", 200);
        $(this).html('Only show GUIs for my OS ('+ capitalizedOS +')');
        $(this).removeClass('filtering');
        $('#os-filter-count').hide();
      }
      else {
        $('ul.gui-thumbnails li').not("."+Downloads.userOS).switchClass("", "masked", 200);
        $(this).html('Show GUIs for all OSes');
        $(this).addClass('filtering');
        var osCount = $('ul.gui-thumbnails li' + '.' + Downloads.userOS).length;
        $('#os-filter-count strong').html(osCount);
        $('#os-filter-count .os').html(capitalizedOS);
        $('#os-filter-count').show();
      }
    });
  }
}

var AboutContent = {
  defaultSection: "branching-and-merging",

  init: function() {
    if ($('body#about').length === 0) return;
    $('section.about').hide();
    $('section.about .bottom-nav').show();
    AboutContent.observeNav();
    AboutContent.observePopState();
    AboutContent.showSection(AboutContent.getSection());
  },

  observePopState: function() {
    if (window.history && window.history.pushState) {
      return $(window).bind('popstate', function(event) {
        var section;
        initialPop = !popped && location.href === initialURL;
        popped = true;
        if (initialPop) {
          return;
        }
        section = AboutContent.getSection();
        return AboutContent.showSection(section);
      });
    }
  },

  getSection: function(href) {
    var section;
    section = location.href.substring(location.href.lastIndexOf("/") + 1);
    if (section.length === 0 || section == 'about') {
      section = AboutContent.defaultSection;
    }
    return section;
  },

  showSection: function(section) {
    if (section == 'about') section = AboutContent.defaultSection;
    $('ol#about-nav a').removeClass('current');
    $('ol#about-nav a#nav-' + section).addClass('current');
    $('section').hide(0, function(){
      $('section#' + section).show();
    });
  },

  observeNav: function() {
    $('ol#about-nav a, .bottom-nav a').click(function(e) {
      e.preventDefault();
      var section = $(this).attr('data-section-id');

      if (window.history && window.history.pushState) {
        history.pushState(null, $(this).html(), '/about/'+section);
      }
      AboutContent.showSection(section);
    });
  }
}

var FlippyBook = {
  threeDee: false,

  init: function() {
    FlippyBook.initBrowsers();
    FlippyBook.observeOpenCloseClicks();
  },

  initBrowsers: function() {
    // only allow webkit since moz 3d transforms are still
    // janky when using z-index
    if (Modernizr.webkit) {
      FlippyBook.threeDee = true;
      $('#book-container').addClass('three-dee');
    }
    $('#about-book').addClass('visible');
  },

  observeOpenCloseClicks: function() {
    $('#book-cover-outside, #open-book').click(function(e) {
      e.preventDefault();
      $('#book-cover').removeClass('close').addClass('open');
      $('#book-intro').css('z-index', '');
      if (!FlippyBook.threeDee) {
        $('#book-cover-inside').show();
        $('#book-inside-page').show();
      }
    });
    $('#about-book').click(function(e) {
      e.preventDefault();
      $('#book-cover').removeClass('open').addClass('close');
      if (FlippyBook.threeDee) {
        var t = setTimeout ("$('#book-intro').css('z-index', 100)", 1000);
      }
      else {
        $('#book-cover-inside').hide();
        $('#book-inside-page').hide();
        $('#book-intro').css('z-index', 100);
      }
    });
  }
}

;
