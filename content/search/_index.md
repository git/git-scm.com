---
section: search
url: /search.html
aliases:
- /search/index.html
---

<header>Search is now client-side only!</header>

<table>
  <tbody><tr class="show-all">
    <td class="category"> &nbsp; </td>
    <td class="matches">
      <ul>
        <li>
          <a class="highlight">Search is now client-side only!</a>
        </li>
        <li>
          Since moving from a full Ruby on Rails app to a static site, the search on https://git-scm.com/ is implemented in Javascript, on the client side. Therefore, the server-side search via https://git-scm.com/search?search=&lt;search-term&gt; is no longer supported.
        </li>
      </ul>
    </td>
  </tr>
</tbody></table>
<script>
  if ($("#search-results").html().indexOf("<header>Search is now client-side only!</header>") > 0) {
    // We seem to be running a client-side search started from the Rails-version of the page;
    // This means that we loaded the _entire_ search page, <html> and all, into the div. Let's not
    // show that while initializing and running the actual search...
    $("#search-results").html("<header>Search results</header><table><tr><td>Initializing search &hellip;</td></tr></table>");
  }
</script>
