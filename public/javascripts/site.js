$(document).ready(function() {		
	BrowserFallbacks.init();
  Search.init();
  Dropdowns.init();
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
  },
  
  observeFocus: function() {
  	$('form#search input').focus(function() {
      $(this).parent('form#search').switchClass("", "focus", 300);
		});
  	$('form#search input').blur(function() {
      $(this).parent('form#search').switchClass("focus", "", 300);
		});
  }
}

var Dropdowns = {
  init: function() {
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
  },
}
;
