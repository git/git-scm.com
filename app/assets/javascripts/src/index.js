import {on} from 'delegated-events'
require("./details")

on('click', '.js-search-link', function(e) {
  const pageBody = document.querySelector('.js-page-body')
  const searchInput = document.querySelector('.js-search-input')
  e.target.closest('.js-site-header').classList.toggle('is-searching')
  pageBody.classList.toggle('is-modaling')
  searchInput.focus()
})

const navLink = document.querySelector('.js-nav-link');

on('click', '.js-nav-link', function(e) {
  const pageBody = document.querySelector('.js-page-body')
  const siteNav = document.querySelector('.js-site-nav')
  pageBody.classList.toggle('is-modaling')
  e.target.closest('.js-site-header').classList.toggle('is-nav-open')
})
