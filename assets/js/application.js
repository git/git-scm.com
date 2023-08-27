// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery-1.7.1.min
//= require jquery-ui-1.8.18.custom.min
//= require jquery.defaultvalue
//= require session.min

// Used to detect initial (useless) popstate.
// If history.state exists, assume browser isn't going to fire initial popstate.
popped = 'state' in window.history;
initialURL = location.href;

const baseURLPrefix = (() => {
  const scripts = document.getElementsByTagName('script');
  const index = scripts.length - 1;
  const thisScript = scripts[index];
  return thisScript.src.replace(/^.*:\/\/[^/]*(.*\/)js\/[^/]+.js(\?.*)?$/, '$1');
})();

$(document).ready(function() {
  BrowserFallbacks.init();
  Search.init();
  Dropdowns.init();
  Forms.init();
  Downloads.init();
  DownloadBox.init();
});

function onPopState(fn) {
  if (window.history && window.history.pushState) {
    return $(window).bind('popstate', function(event) {
      var section;
      initialPop = !popped && location.href === initialURL;
      popped = true;
      if (initialPop) {
        return;
      }
      fn();
    });
  }
}

var DownloadBox = {
  init: function() {
    $('#gui-os-filter').addClass('visible');
    var os = window.session.browser.os; // Mac, Win, Linux
    if(os == "Mac") {
      $(".monitor").addClass("mac");
      $("#download-link").text("Download for Mac").attr("href", `${baseURLPrefix}download/mac`);
      $("#gui-link").removeClass('mac').addClass('gui');
      $("#gui-link").text("Mac GUIs").attr("href", `${baseURLPrefix}download/gui/mac`);
      $("#gui-os-filter").attr('data-os', 'mac');
      $("#gui-os-filter").text("Only show GUIs for my OS (Mac)")
    } else if (os == "Windows") {
      $(".monitor").addClass("windows");
      $("#download-link").text("Download for Windows").attr("href", `${baseURLPrefix}download/win`);
      $("#gui-link").removeClass('mac').addClass('gui');
      $("#gui-link").text("Windows GUIs").attr("href", `${baseURLPrefix}download/gui/windows`);
      $("#alt-link").removeClass("windows").addClass("mac");
      $("#alt-link").text("Mac Build").attr("href", `${baseURLPrefix}download/mac`);
      $("#gui-os-filter").attr('data-os', 'windows');
      $("#gui-os-filter").text("Only show GUIs for my OS (Windows)")
    } else if (os == "Linux") {
      $(".monitor").addClass("linux");
      $("#download-link").text("Download for Linux").attr("href", `${baseURLPrefix}download/linux`);
      $("#gui-link").removeClass('mac').addClass('gui');
      $("#gui-link").text("Linux GUIs").attr("href", `${baseURLPrefix}download/gui/linux`);
      $("#alt-link").removeClass("windows").addClass("mac");
      $("#alt-link").text("Mac Build").attr("href", `${baseURLPrefix}download/mac`);
      $("#gui-os-filter").attr('data-os', 'linux');
      $("#gui-os-filter").text("Only show GUIs for my OS (Linux)")
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
  currentSearch: '',
  selectedIndex: 0,

  init: function() {
    Search.displayFullSearchResults();
    Search.observeFocus();
    Search.observeTextEntry();
    Search.observeResultsClicks();
    Search.installKeyboardShortcuts();
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
    $('form#search input').keyup(function(e) {
      Search.runSearch();
    });

    $('form#search input').keydown(function(e) {
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
      };
    });
  },

  observeResultsClicks: function() {
    $('#search-results').mousedown(function(e) {
      e.preventDefault();
    });
  },

  installKeyboardShortcuts: function() {
    $(document).keydown(function(e) {
      if (e.target.tagName.toUpperCase() !== 'INPUT' && ['s', 'S', '/'].includes(e.key)) {
        e.preventDefault();
        $('form#search input').focus();
      }
    });
  },

  runSearch: function() {
    var term = $('#search-text').val();
    if(term.length < 2) { return false };

    if(!Search.searching) {
      Search.searching = true;

      if(term != Search.currentSearch) {
        Search.currentSearch = term;
        $("#search-results").html(`
          <header> Search Results </header>
          <table>
            <tbody>
              <tr class="show-all">
               <td class="category"> &nbsp; </td>
                <td class="matches">
                  <ul>
                    <li>
                      <a class="highlight" id="show-results-label">Searching for <span id="search-term">&nbsp;</span>...</a>
                    </li>
                  </ul>
                </td>
              </tr>
              <tr style="display:none">
                <td class="category">Reference</td>
                <td class="matches">
                  <ul id="ul-reference"></ul>
                </td>
              </tr>
              <tr style="display:none">
                <td class="category">Book</td>
                <td class="matches">
                  <ul id="ul-book"></ul>
                </td>
              </tr>
              <tr id="row-any">
                <td class="category"> &nbsp; </td>
                <td class="matches">
                  <ul>
                    <li><button id="load-more-results">Loading</button></li>
                  </ul>
                </td>
              </tr>
            </tbody>
          </table>
        `);
        $("#search-term").text(term);
        this.initializeSearchIndex(async () => {
          const results = await Search.pagefind.debouncedSearch(term);
          if (results === null) return;
          if (results.results.length === 0) {
            $("#show-results-label").text("No matching pages found.");
            return;
          }
          $("#show-results-label").text("Show all results...");
          const loadButton = $("#load-more-results");
          loadButton.text(`Loading ${
            results.results.length < 2
            ? "result"
            : `${results.results.length} results`
          }`);
          loadButton.loading = false;

          const ulReference = $("#ul-reference")
          const ulBook = $("#ul-book")

          const chunkLength = 10;
          let displayCount = 0;

          const categorizeResult = (i) => {
            while (i < displayCount && typeof results.results[i].data === 'object') {
              const result = results.results[i++];
              if (result.data.meta.category === 'Reference') {
                if (ulReference.children().length === 0) ulReference.parent().parent().css("display", "table-row")
                ulReference.append(result.li)
              } else if (result.data.meta.category === 'Book') {
                if (ulBook.children().length === 0) ulBook.parent().parent().css("display", "table-row")
                ulBook.append(result.li)
              }
            }
          };

          const loadResultsChunk = () => {
            if (loadButton.loading || displayCount >= results.results.length) return;

            loadButton.loading = true;
            const n = displayCount + chunkLength;
            while (displayCount < n) {
              const result = results.results[displayCount]
              result.li = $("<li><a>&hellip;</a></li>");
              result.li.insertBefore(loadButton);

              // load the result lazily
              (async (i) => {
                result.data = await results.results[displayCount].data();
                if (!i || typeof results.results[i - 1].data === 'object') categorizeResult(i);
                result.data.meta.title = result.data.meta.title.replace(/^Git - (.*) Documentation$/, "$1")
                result.data.url = result.data.url.replace(/\.html$/, '')
                result.li.html(`<a href = "${result.data.url}">${result.data.meta.title}</a>`);
              })(displayCount).catch((err) => {
                console.log(err);
                result.li.html(`<i>Error loading result</i>`);
              });

              if (++displayCount >= results.results.length) {
                loadButton.remove();
                return;
              }
            }
            const remaining = results.results.length - displayCount;
            loadButton.text(`Load ${remaining} more ${remaining < 2 ? "result" : "results"}`);
            loadButton.loading = false;
          };
          loadResultsChunk();
          loadButton.on("click", loadResultsChunk);
          Search.searching = false;
        });
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
    var link = $('#search-results a')[Search.selectedIndex];
    var url = $(link).attr('href');
    if(!url) {
      const term = $('#search-text').val();
      const language = document.querySelector("html")?.getAttribute("lang");
      url = `${baseURLPrefix}search/results?search=${term}${language && `&language=${language}`}`;
    }
    window.location.href = url;
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
  },

  getQueryValue: function(key) {
    const query = window.location.search.substring(1);
    const needle = `${key}=`;
    return query
      .split('&')
      .filter(e => e.startsWith(needle))
      .map(e => decodeURIComponent(e.substring(needle.length).replace(/\+/g, '%20')))
      .pop();
  },

  initializeSearchIndex: function(callback) {
    if (Search.pagefind) {
      callback().catch(console.log);
      return;
    }
    (async () => {
      Search.pagefind = await import(`${baseURLPrefix}pagefind/pagefind.js`);
      const options = {
        ranking: {
          pageLength: 0.1, // boost longer pages
          termFrequency: 0.1, // do not favor short pages
          termSaturation: 2, // look for pages with more matches
          termSimilarity: 9, // prefer exact matches
        }
      }
      const language = this.getQueryValue('language');
      if (language) options.language = language;
      await Search.pagefind.options(options);
      await Search.pagefind.init();
      await callback();
    })().catch(console.log);
  },

  displayFullSearchResults: function() {
    if (!$("#search-div").length) return;

    const language = this.getQueryValue('language');

    const ui = new PagefindUI({
      element: "#search-div",
      showSubResults: true,
      showImages: false,
      language,
      ranking: {
        pageLength: 0.1, // boost longer pages
        termFrequency: 0.1, // do not favor short pages
        termSaturation: 2, // look for pages with more matches
        termSimilarity: 9, // prefer exact matches
      },
      processResult: function (result) {
        result.url = result.url.replace(/\.html$/, "")
        return result
      },
    });

    const searchTerm = this.getQueryValue('search');
    if (searchTerm) {
      $("#search-div input").val(searchTerm)
      ui.triggerSearch(searchTerm);
    }
  }
}

var Dropdowns = {
  init: function() {
    Dropdowns.observeTriggers();
  },

  observeTriggers: function() {
    var eles = $('.dropdown-trigger');
    eles.click(function(e) {
      e.preventDefault();

      $(this).toggleClass('active');
      $('#' + $(this).attr('data-panel-id')).toggle();

      eles.each((_, ele)=>{
        if(ele === this) return
        $(ele).removeClass('active');
        $('#' + $(ele).attr('data-panel-id')).hide();
      })
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
  init: function() {
    Downloads.observeGUIOSFilter();
    Downloads.observePopState();
    Downloads.filterGUIS();
    Downloads.postProcessDownloadPage();
  },

  getOSFromQueryString: function() {
    const query = window.location.search.substring(1);
    const needle = `os=`;
    return query
      .split('&')
      .filter(e => e.startsWith(needle))
      .map(e => decodeURIComponent(e.substring(needle.length).replace(/\+/g, '%20')))
      .pop();
  },

  getOSFilter: function(os) {
    os = os || Downloads.getOSFromQueryString();
    return os === 'linux' || os === 'mac' || os === 'windows' || os === 'android' || os === 'ios' ? os : '';
  },

  capitalizeOS: function(os) {
    const platforms = {"linux": "Linux", "mac": "Mac", "windows": "Windows", "android": "Android", "ios": "iOS"};
    return platforms[os];
  },

  filterGUIS: function(os) {
    var osFilter = Downloads.getOSFilter(os);
    var capitalizedOS = Downloads.capitalizeOS(osFilter);
    $('a.gui-os-filter').not("[data-os='"+osFilter+"']").removeClass('selected');
    $('a.gui-os-filter').filter("[data-os='"+osFilter+"']").addClass('selected');

    if (osFilter === '') {
      $('ul.gui-thumbnails li').removeClass("masked");
      $('#os-filter-count').hide();
    }
    else {
      $('ul.gui-thumbnails li').filter("."+osFilter).removeClass('masked');
      $('ul.gui-thumbnails li').not("."+osFilter).addClass('masked');
      var osCount = $('ul.gui-thumbnails li' + '.' + osFilter).length;
      $('#os-filter-count strong').html(osCount);
      $('#os-filter-count .os').html(capitalizedOS);
      $('#os-filter-count').show();
    }
  },

  observeGUIOSFilter: function() {
    $('a.gui-os-filter').click(function(e) {
      e.preventDefault();
      var os = $(this).attr('data-os');

      if (window.history && window.history.pushState) {
        var url = os === ''
          ? `${baseURLPrefix}downloads/guis`
          : `${baseURLPrefix}download/guis?os=${os}`;
        try {
          history.pushState(null, $(this).html(), url);
        } catch (e) {
          if (`${e}`.indexOf('The operation is insecure') < 0) console.log(e)
        }
      }

      Downloads.filterGUIS(os);
    });
  },

  observePopState: function() {
    onPopState(function() {
      Downloads.filterGUIS();
    });
  },

  // say how many days ago this version was released
  postProcessReleaseDate: function(index, releaseDateString) {
    const daysAgo = Math.floor((Date.now() - Date.parse($('#auto-download-date').html())) / 86400000);
    if (daysAgo < 0) return releaseDateString; // leave unparseable content alone

    const rest = (count, unit) => `${count} ${unit}${count > 1 ? "s" : ""} ago`;
    let ago = rest(daysAgo, "day");

    const handwave = (exact, unit) => {
      const roundedDown = Math.floor(exact);
      const fract = exact - roundedDown;
      if (fract < 0.25) return `about ${rest(roundedDown, unit)}`;
      if (fract < 0.75) return `over ${rest(roundedDown, unit)}`;
      return `almost ${rest(roundedDown + 1, unit)}`;
    }

    if (daysAgo == 0) ago = "today";
    else if (daysAgo == 1) ago = "yesterday";
    // from here on out, we keep it only approximately exact
    else if (daysAgo > 365 * 0.75) ago = handwave(daysAgo / 365.25, "year");
    else if (daysAgo > 45) ago = handwave(daysAgo / 30.4, "month");
    return `<strong>${ago}</strong>, `;
  },

  adjustFor32BitWindows: function() {
    // adjust the auto-link for Windows 32-bit setups
    const is32BitWindows = window.session.browser.os === 'Windows'
      && !navigator.userAgent.match(/WOW64|Win64|x64|x86_64/)
    if (!is32BitWindows) return;

    const link = $('#auto-download-link');
    const version = $('#auto-download-version');
    const bitness = $('#auto-download-bitness');
    const date = $('#auto-download-date');
    if (link.length && version.length && bitness.length && date.length) {
      bitness.html('32-bit');
      link.attr('href', '{{ .Site.Params.windows_installer.installer32.url }}');
      version.html('{{ .Site.Params.windows_installer.installer32.version }}');
      date.html('{{ .Site.Params.windows_installer.installer32.release_date }}');
    }
  },

  postProcessDownloadPage: function() {
    Downloads.adjustFor32BitWindows();
    $('#relative-release-date').html(Downloads.postProcessReleaseDate);
  },
}

// Scroll to Top
$('#scrollToTop').removeClass('no-js');
$(window).scroll(function() {
  $(this).scrollTop() > 150
    ? $('#scrollToTop').fadeIn()
    : $('#scrollToTop').fadeOut();
});
$('#scrollToTop').click(function(e) {
  e.preventDefault();
  $("html, body").animate({
      scrollTop: 0
  }, "slow");
  return false;
});
