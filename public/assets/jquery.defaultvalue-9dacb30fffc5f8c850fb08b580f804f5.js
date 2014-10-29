(function($) { 

  $.fn.defaultValue = function(text, activeClass, inactiveClass){
    return this.each(function(){
      if (this.type != 'text' && this.type != 'password' && this.type != 'textarea')
      return;

      // Store field reference
      var fld_current = this;

      // Set value initially if none are specified
      if ($(this).val() == '') {
        if (inactiveClass != null) { $(this).addClass(inactiveClass); }
        $(this).val(text);
      } else {
        // Other value exists – ignore
        return;
      }

      // Add class on focus
      $(this).focus(function() {
        if ($(this).val() == text || $(this).val() == '') {
          if (inactiveClass != null) { $(this).removeClass(inactiveClass); }
          if (activeClass != null) { $(this).addClass(activeClass); }
          $(this).val('');
        }
      });

      // Remove class on blur
      $(this).blur(function() {
        if ($(this).val() == text || $(this).val() == '') {
          if (activeClass != null) { $(this).removeClass(activeClass); }
          if (inactiveClass != null) { $(this).addClass(inactiveClass); }
          $(this).val(text);
        }
      });

    });
  };

})(jQuery);
