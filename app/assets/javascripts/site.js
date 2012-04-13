$(document).ready(function() {		
  BrowserFallbacks.init();
  Search.init();
  Dropdowns.init();
  Forms.init();
  Downloads.init();

});

var Downloads = {
  init: function() {
    var os = window.session.browser.os; // Mac, Win, Linux
    os = "Win"
    if(os == "Mac") {
      // we default to mac
    } else if (os == "Win") {
      $(".monitor").removeClass("mac");
      $(".monitor").addClass("windows");
      $("#download-link").text("Download for Windows").attr("href", "/download/win");
      $("#gui-link").text("Windows GUI").attr("href", "/download/gui/win");
      $("#alt-link").removeClass("windows").addClass("mac");
      $("#alt-link").text("Mac Build").attr("href", "/download/mac");
    } else if (os == "Linux") {
      $(".monitor").removeClass("mac");
      $(".monitor").addClass("linux");
      $("#download-link").text("Download for Linux").attr("href", "/download/linux");
      $("#gui-link").text("Linux GUI Client").attr("href", "/download/gui/linux");
      $("#alt-link").removeClass("windows").addClass("mac");
      $("#alt-link").text("Mac Build").attr("href", "/download/mac");
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
  selectedIndex: 0,

  init: function() {
    Search.observeFocus();
    Search.observeTextEntry();
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
    $('form#search input').keydown(function(e) {
      Search.searching = true;
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
        default:
          // execute search with current text
          Search.runSearch(e.which);
          break;
      };
    });
  },

  runSearch: function(lastLetter) {
    var term = $('#search-text').val() + String.fromCharCode(lastLetter);
    $.get("/search", {search: term}, function(results) {
      $("#search-results").html(results);
    });
  },

  selectResultOption: function() {
    var link = $('#search-results a')[Search.selectedIndex];
    window.location.href = $(link).attr('href');
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
