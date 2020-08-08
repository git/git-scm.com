import {on} from 'delegated-events'

on('click', '.js-details-container .js-details-target', function(event) {
  const container = this.closest('.js-details-container')
  container.classList.toggle('open')
  event.preventDefault()
})
