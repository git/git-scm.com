import {on} from 'delegated-events'

on('change', '.js-book-lang', function(event) {
  const option = event.target
  const lang = option[option.selectedIndex].value;
  window.location = `/book/${lang}`
})
