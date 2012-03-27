$(document).ready(function() {		
	BrowserFallbacks.init();
  Search.init();
  Dropdowns.init();
  Forms.init();
});

var BrowserFallbacks = {
  init: function() {
    BrowserFallbacks.initPlaceholders();
  },

  initPlaceholders: function() {
    if (!Modernizr.input.placeholder) {
      alert('yo');
      $('input[placeholder], textarea[placeholder]').each(function(input) {
        $(this).defaultValue($(this).attr('placeholder'), 'active', 'inactive');
      });
    }
  }

}

var Search = {
  init: function() {
    Search.observeFocus();
    Search.observeTextEntry();
  },
  
  observeFocus: function() {
  	$('form#search input').focus(function() {
      $(this).parent('form#search').switchClass("", "focus", 200);
		});
  	$('form#search input').blur(function() {
      $(this).parent('form#search').switchClass("focus", "", 200);
      $('#search-results').fadeOut(0.2);
		});
  },

  observeTextEntry: function() {
    $('form#search input').keyup(function() {
      $('#search-results').fadeIn(0.2);
    });
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