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
    $('.js-gui-os-filter').addClass('visible');
    var os = window.session.browser.os; // Mac, Win, Linux
    if(os == "Mac") {
      $(".monitor").addClass("mac");
      $(".js-download-link").text("Downloads for Mac").attr("href", "/download/mac");
      $(".js-gui-link").removeClass('mac').addClass('gui');
      $(".js-gui-link").text("Mac GUIs").attr("href", "/download/gui/mac");
      $(".js-gui-os-filter").attr('data-os', 'mac');
      $(".js-gui-os-filter").text("Only show GUIs for my OS (Mac)")
    } else if (os == "Windows") {
      $(".monitor").addClass("windows");
      $(".js-download-link").text("Downloads for Windows").attr("href", "/download/win");
      $(".js-gui-link").removeClass('mac').addClass('gui');
      $(".js-gui-link").text("Windows GUIs").attr("href", "/download/gui/win");
      $(".js-alt-link").removeClass("windows").addClass("mac");
      $(".js-alt-link").text("Mac Build").attr("href", "/download/mac");
      $(".js-gui-os-filter").attr('data-os', 'windows');
      $(".js-gui-os-filter").text("Only show GUIs for my OS (Windows)")
    } else if (os == "Linux") {
      $(".monitor").addClass("linux");
      $(".js-download-link").text("Downloads for Linux").attr("href", "/download/linux");
      $(".js-gui-link").removeClass('mac').addClass('gui');
      $(".js-gui-link").text("Linux GUIs").attr("href", "/download/gui/linux");
      $(".js-alt-link").removeClass("windows").addClass("mac");
      $(".js-alt-link").text("Mac Build").attr("href", "/download/mac");
      $(".js-gui-os-filter").attr('data-os', 'linux');
      $(".js-gui-os-filter").text("Only show GUIs for my OS (Linux)")
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
        $(this).defaultValue($(this).attr('placeholder'), 'input-active', 'input-inactive');
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
    $('.js-search-text').focus(function() {
      $('.js-search-form').switchClass("", "focus", 200);
    });
    $('.js-search-text').blur(function() {
      Search.resetForm();
    });
  },

  observeTextEntry: function() {
    $('.js-search-text').keyup(function(e) {
      Search.runSearch();
    });

    $('.js-search-text').keydown(function(e) {
      if ($('.js-search-results').not(':visible') && e.which != 27) {
        $('.js-search-results').fadeIn(0.2);
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
    $('.js-search-results').mousedown(function(e) {
      e.preventDefault();
    });
  },

  runSearch: function() {
    var term = $('.js-search-text').val();
    if(term.length < 2) { return false };

    if(!Search.searching) {
      Search.searching = true;

      if(term != Search.currentSearch) {
        Search.currentSearch = term;
        $.get("/search", {search: term}, function(results) {
          $(".js-search-results").html(results);
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
    var link = $('.js-search-results a')[Search.selectedIndex];
    var url = $(link).attr('href');
    if(!link) {
      var term = $('.js-search-text').val();
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
    var links = $('.js-search-results a').removeClass('highlight');
    $(links[index]).addClass('highlight');
  },

  resetForm: function() {
    $('.js-search-form').switchClass("focus", "", 200);
    $('.js-search-results').fadeOut(0.2);
    Search.selectedIndex = 0;
  }
}

var Dropdowns = {
  init: function() {
    Dropdowns.observeTriggers();
  },

  observeTriggers: function() {
    $('.js-dropdown-trigger').click(function(e) {
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
    $('.js-gui-os-filter').click(function(e) {
      e.preventDefault();
      Downloads.userOS = $(this).attr('data-os');
      var capitalizedOS = Downloads.userOS.charAt(0).toUpperCase() + Downloads.userOS.slice(1);
      if ($(this).hasClass('filtering')) {
        $('ul.gui-thumbnails li').switchClass("masked", "", 200);
        $(this).html('Only show GUIs for my OS ('+ capitalizedOS +')');
        $(this).removeClass('filtering');
        $('.js-os-filter-count').hide();
      }
      else {
        $('ul.gui-thumbnails li').not("."+Downloads.userOS).switchClass("", "masked", 200);
        $(this).html('Show GUIs for all OSes');
        $(this).addClass('filtering');
        var osCount = $('ul.gui-thumbnails li' + '.' + Downloads.userOS).length;
        $('.js-os-filter-count strong').html(osCount);
        $('.js-os-filter-count .os').html(capitalizedOS);
        $('.js-os-filter-count').show(); }
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
    $('.js-about-nav a').removeClass('current');
    $('.js-about-nav a#nav-' + section).addClass('current');
    $('section').hide(0, function(){
      $('section#' + section).show();
    });
  },

  observeNav: function() {
    $('.js-about-nav a, .bottom-nav a').click(function(e) {
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
      $('.js-book-container').addClass('three-dee');
    }
    $('.js-flippy-book-about-link').addClass('visible');
  },

  observeOpenCloseClicks: function() {
    $('.js-flippy-book-cover-outside, .open-book-link').click(function(e) {
      e.preventDefault();
      $('.js-flippy-book-cover').removeClass('close').addClass('open');
      $('.js-book-intro').css('z-index', '');
      if (!FlippyBook.threeDee) {
        $('.js-flippy-book-cover-inside').show();
        $('.js-flippy-book-inside-page').show();
      }
    });
    $('.js-flippy-book-about-link').click(function(e) {
      e.preventDefault();
      $('.js-flippy-book-cover').removeClass('open').addClass('close');
      if (FlippyBook.threeDee) {
        var t = setTimeout ("$('.js-book-intro').css('z-index', 100)", 1000);
      }
      else {
        $('.js-flippy-book-cover-inside').hide();
        $('.js-flippy-book-inside-page').hide();
        $('.js-book-intro').css('z-index', 100);
      }
    });
  }
}

