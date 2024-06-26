//= require modernizr

Modernizr.addTest('webkit', function(){
  return RegExp(" AppleWebKit/").test(navigator.userAgent);
});

Modernizr.addTest('chrome', function(){
  return RegExp(" Chrome/").test(navigator.userAgent);
});

Modernizr.addTest('windows', function(){
  return RegExp("Win").test(navigator.platform);
});

Modernizr.addTest('ie8', function(){
  return RegExp("MSIE 8").test(navigator.userAgent);
});
