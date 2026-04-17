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
//= require jquery.defaultvalue
//= require session.min

// Used to detect initial (useless) popstate.
// If history.state exists, assume browser isn't going to fire initial popstate.
popped = 'state' in window.history;
initialURL = location.href;

const baseURLPrefix = (() => {
  const thisScriptSrc =
    Array.from(document.getElementsByTagName('script'))
      .pop()
      .getAttribute('src');
  return thisScriptSrc
    .replace(/^(?:[a-z]*:\/\/[^/]*)?(.*\/)(assets|js)\/[^/]+.js(\?.*)?$/, '$1');
})();

$(document).ready(function() {
  BrowserFallbacks.init();
  DarkMode.init();
  GitTurns20.init();
  Search.init();
  Dropdowns.init();
  Forms.init();
  Downloads.init();
  DownloadBox.init();
  InstallPageLink.init();
  PostelizeAnchor.init();
  Print.init();
});

function onPopState(fn) {
  if (window.history && window.history.pushState) {
    return $(window).on('popstate', function() {
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
      $("#download-link").text("Install for Mac").attr("href", `${baseURLPrefix}install/mac`);
      $("#gui-os-filter").attr('data-os', 'mac');
      $("#gui-os-filter").text("Only show GUIs for my OS (Mac)")
    } else if (os == "Windows") {
      $("#download-link").text("Install for Windows").attr("href", `${baseURLPrefix}install/windows`);
      $("#gui-os-filter").attr('data-os', 'windows');
      $("#gui-os-filter").text("Only show GUIs for my OS (Windows)")
    } else if (os == "Linux") {
      $("#download-link").text("Install for Linux").attr("href", `${baseURLPrefix}install/linux`);
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

var GitTurns20 = {
  keySequence: '20',
  keySequenceOffset: 0,

  init: function() {
    const today = new Date();
    if (today.getFullYear() === 2025 && today.getMonth() === 3 && today.getDate() === 7) {
      this.celebrate();
    } else {
      let start = 0
      let count = 0
      $("#tagline").on('click', e => {
        if (count === 0 || e.timeStamp > start + count * 1000) {
          start = e.timeStamp;
          count = 1;
        } else if (++count === 6) {
          this.celebrate();
          count = 0;
        }
      })
    }
  },

  keydown: function(e) {
    if (this.keySequenceOffset >= this.keySequence.length) return;
    if (this.keySequence[this.keySequenceOffset] === e.key) {
      if (++this.keySequenceOffset === this.keySequence.length) {
        this.celebrate();
        this.keySequenceOffset = 0;
      }
    }
  },

  celebrate: function() {
    document.documentElement.dataset.celebration = 'git-turns-20';
    $("#tagline").html('<a href="https://discord.gg/UcjvsNQR">--20th-anniversary</a>');
    if ($("#masthead").length) { // only do this on the front page
      (async () => {
        await import('https://cdn.jsdelivr.net/npm/canvas-confetti@1.9.3/dist/confetti.browser.min.js');
        const count = 200;
        const defaults = {
          origin: { y: 0.7 },
          disableForReducedMotion: true,
        };

        for (const [particleRatio, opts] of [
          [0.25, { spread: 26, startVelocity: 55 }],
          [0.2, { spread: 60 }],
          [0.35, { spread: 100, decay: 0.91, scalar: 0.8 }],
          [0.1, { spread: 120, startVelocity: 25, decay: 0.92, scalar: 1.2 }],
          [0.1, { spread: 120, startVelocity: 45 }],
        ]) {
          window.confetti({
            ...defaults,
            ...opts,
            particleCount: Math.floor(count * particleRatio)
          });
        }
      })().catch(console.error);
    }
  }
};

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
    $('form#search input').on('focus', function() {
      $(this).parent('form#search').switchClass("", "focus", 200);
    });
    $('form#search input').on('blur', function() {
      Search.resetForm();
    });
  },

  observeTextEntry: function() {
    $('form#search input').on('keyup', function() {
      Search.runSearch();
    });

    $('form#search input').on('keydown', function(e) {
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
    $('#search-results').on('mousedown', function(e) {
      e.preventDefault();
    });
  },

  installKeyboardShortcuts: function() {
    $(document).on('keydown', function(e) {
      if (e.target.tagName.toUpperCase() !== 'INPUT' && ['s', 'S', '/'].includes(e.key)) {
        e.preventDefault();
        $('form#search input').trigger('focus');
      }
      else if (e.target.tagName.toUpperCase() !== 'INPUT') GitTurns20.keydown(e);
    });
  },

  runSearch: function() {
    var term = $('#search-text').val();
    if(term.length < 2) { return false };

    if(!Search.searching) {
      Search.searching = true;

      if(term != Search.currentSearch) {
        Search.currentSearch = term;
        const language = document.querySelector("html")?.getAttribute("lang");
        const allResultsURL = `${baseURLPrefix}search/results?search=${encodeURIComponent(term)}${language && `&language=${encodeURIComponent(language)}`}`;
        $("#search-results").html(`
          <header> Search Results </header>
          <table>
            <tbody>
              <tr class="show-all">
               <td class="category"> &nbsp; </td>
                <td class="matches">
                  <ul>
                    <li>
                      <a class="highlight" id="show-results-label">
                        Searching for <span id="search-term">&nbsp;</span>...
                      </a>
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
        // Set the link target safely (no HTML parsing).
        $("#show-results-label").attr("href", allResultsURL);

        this.initializeSearchIndex(async () => {
          const results = await Search.pagefind.debouncedSearch(term);
          if (results === null || results.results.length === 0) {
            $("#show-results-label").text("No matching pages found.");
            return;
          }
          $("#show-results-label")
            .text("Show all results...")

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
                // Build result item safely (no HTML parsing).
                const a = $("<a>");
                a.attr("href", result.data.url);
                a.text(result.data.meta.title);
                result.li.empty().append(a);
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
    if (!url) {
      const term = $('#search-text').val();
      if (!term) return;
      const language = document.querySelector("html")?.getAttribute("lang");
      url = `${baseURLPrefix}search/results?search=${encodeURIComponent(term)}${language && `&language=${encodeURIComponent(language)}`}`;
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
      const pagefindURL =
        `${baseURLPrefix}pagefind/pagefind.js`
          // adjust the `baseURLPrefix` if it is relative: the `import`
          // is relative to the _script URL_ here, which is in /js/.
          // That is different from other uses of `baseURLPrefix`, which
          // replace `href` and `src` attributes which are relative to the
          // page itself that is outside of /js/.
          .replace(/^\.\//, '../')
      Search.pagefind = await import(pagefindURL);
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
      showEmptyFilters: false,
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
    eles.on('click', function(e) {
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
    $('input.copyable').on('click', function() {
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
    $('a.gui-os-filter').on('click', function(e) {
      e.preventDefault();
      var os = $(this).attr('data-os');

      if (window.history && window.history.pushState) {
        var url = os === ''
          ? `${baseURLPrefix}downloads/guis`
          : `${baseURLPrefix}downloads/guis?os=${os}`;
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

  adjustForWindowsARM64: function() {
    /*
     * Windows/ARM64 cannot be reliably detected via the User-Agent string;
     * Instead, we use the UAData, but that is not available in all browsers.
     * For more details, see
     * https://github.com/git-for-windows/git-for-windows.github.io/pull/61
     */
    if (!navigator.userAgentData) return;

    navigator.userAgentData.getHighEntropyValues(['architecture', 'platform', 'bitness'])
		  .then(function(browser) {
				if (
          browser.platform !== 'Windows'
          || browser.bitness !== '64'
          || browser.architecture !== 'arm'
        ) return;

        // adjust the auto-link for Windows/ARM64 setups
        const link = $('#auto-download-link');
        const version = $('#auto-download-version');
        const architecture = $('#auto-download-architecture');
        const date = $('#auto-download-date');
        if (link.length && version.length && architecture.length && date.length) {
          architecture.html('ARM64');
          link.attr('href', '{{ .Site.Params.windows_installer.installer_arm64.url }}');
          version.html('{{ .Site.Params.windows_installer.installer_arm64.version }}');
          date.html('{{ .Site.Params.windows_installer.installer_arm64.release_date }}');
        }
      })
  },

  postProcessDownloadPage: function() {
    Downloads.adjustForWindowsARM64();
    $('#relative-release-date').html(Downloads.postProcessReleaseDate);
  },
}

var DarkMode = {
  init: function() {
    const button = $('#dark-mode-button');
    if (!button.length) return;

    // Check for dark mode preference at the OS level
    const prefersDarkScheme = window.matchMedia("(prefers-color-scheme: dark)").matches;

    // Get the user's theme preference from local storage, if it's available
    const currentTheme = localStorage.getItem("theme");

    if ((prefersDarkScheme && currentTheme !== "light")
        || (!prefersDarkScheme && currentTheme === "dark")) {
      button.attr("src", `${baseURLPrefix}images/light-mode.svg`);
    }
    button.addClass('active');

    button.on('click', function(e) {
      e.preventDefault();
      let theme
      if (prefersDarkScheme) {
        theme = document.documentElement.dataset.theme === "light" ? "dark" : "light"
      } else {
        theme = document.documentElement.dataset.theme === "dark" ? "light" : "dark"
      }
      document.documentElement.dataset.theme = theme
      if (prefersDarkScheme === (theme === "dark")) localStorage.removeItem("theme");
      else localStorage.setItem("theme", theme);
      button.attr("src", `${baseURLPrefix}images/${theme === "dark" ? "light" : "dark"}-mode.svg`);
    });
  },
}

/*
 * Respect Postel's Law when an invalid anchor was specified;
 * Try to find the most similar existing anchor and then use
 * that.
 */
var PostelizeAnchor = {
  init: function() {
    const anchor = window.location.hash;
    if (
      !anchor
      || !anchor.startsWith("#")
      || anchor.length < 2
      || document.querySelector(CSS.escape(anchor)) !== null
    ) return;

    const id = anchor.slice(1);
    const maxD = id.length / 2;
    const ids = [...document.querySelectorAll('[id]')].map(e => e.id);
    const closestID = ids.reduce((a, e) => {
      const d = PostelizeAnchor.wuLevenshtein(id, e, maxD);
      if (d < a.d) {
        a.d = d;
        a.id = e;
      }
      return a;
    }, { d: maxD }).id;
    if (closestID) window.location.hash = `#${closestID}`;
  },
  /*
   * Wu's algorithm to calculate the "simple Levenshtein" distance, i.e.
   * the minimal number of deletions and insertions needed to transform
   * str1 to str2.
   *
   * The optional `maxD` parameter can be used to cap the distance (and
   * the runtime of the function).
   */
  wuLevenshtein: function(str1, str2, maxD) {
    const len1 = str1.length;
    const len2 = str2.length;
    if (len1 === 0) return len2;
    if (len2 === 0) return len1;

    /*
     * The idea is to navigate within the matrix that has len1 columns and len2
     * rows and which contains the edit distances d (the sum of
     * deletions/insertions) between the prefixes str1[0..x] and str2[0..y]. This
     * is done by looping over d, starting at 0, skipping along the diagonals
     * where str1[x] === str2[y] (which does not change d), storing the maximal x
     * value of each diagonal (characterized by k := x - y) in V[k + offset]. The
     * valid diagonals k range from -len2 to len1.
     *
     * Once x reaches the length of str1 and y the length of str2, the edit
     * distance between str1 and str2 has been found.
     *
     * Allocate a vector V of size (len1 + len2 + 1) so that index = k + offset,
     * with offset = len2 (since k can be negative, but JavaScript does not
     * support negative array indices).
     *
     * We can get away with a single array V because adjacent d values on
     * neighboring diagonals differ by 1, meaning that even k values correspond
     * to even d values, and odd k values to odd d values. Therefore, in loop
     * iterations where d is odd, V[k] is read out at even k values and modified
     * at odd k values.
     */
    const size = len1 + len2 + 1;
    const V = new Array(size).fill(0);
    const offset = len2;

    if (maxD === undefined) maxD = len1 + len2;
    // d is the edit distance (insertions/deletions)
    for (let d = 0; d < maxD; d++) {
      // k can only be between max(-len2, -d) and min(len1, d)
      // and we step in increments of 2.
      for (let k = Math.max(-len2, -d); k <= len1 && k <= d; k += 2) {
        const kIndex = k + offset;
        let x;

        /*
         * Decide whether to use an insertion or a deletion:
         * - If k is -d, x (i.e. the offset in str1) must be 0 and nothing can be
         *   deleted,
         * - If k is d, V[kIndex + 1] hasn't been calculated in the previous
         *   loop iterations, therefore it must be a deletion,
         * - Otherwise, choose the direction that allows reaching furthest in
         *   str1, i.e. maximize x (and therefore also y).
	 */
        if (k === -d || (k !== d && V[kIndex - 1] < V[kIndex + 1])) {
          // Insertion: from diagonal k+1 (i.e. we move down in str2)
          x = V[kIndex + 1];
        } else {
          // Deletion: from diagonal k-1 (i.e. we move right in str1)
          x = V[kIndex - 1] + 1;
        }

        // Compute y based on the diagonal: y = x - k.
        let y = x - k;

        // Follow the “snake” (i.e. match characters along the diagonal).
        while (x < len1 && y < len2 && str1[x] === str2[y]) {
          x++;
          y++;
        }
        V[kIndex] = x;

        // If we've reached the ends of both strings, then we've found the answer.
        if (x >= len1 && y >= len2) {
          return d;
        }
      }
    }
    return maxD;
  },
}

var Graphviz = {
  render: function() {
    let vizInstance
    [...document.querySelectorAll("pre[class=graphviz]")].forEach(async (x) => {
      if (!vizInstance) vizInstance = await Viz.instance()
      const options = {
        format: "svg",
        graphAttributes: {
          bgcolor: "transparent",
        },
        engine: x.getAttribute("engine") || "dot",
      }
      const svg = vizInstance.renderString(x.innerText, options)
      const img = document.createElement('img')
      img.setAttribute(
        'src',
        `data:image/svg+xml;utf8,${encodeURIComponent(svg.substring(svg.indexOf('<svg')))}`
      )
      const alt = x.getAttribute("alt")
      if (alt) img.setAttribute("alt", alt)
      x.parentNode.insertBefore(img, x);
      x.style.display = 'none'
    });
  }
}

var InstallPageLink = {
  init: function() {
    const installLink = document.querySelector('.install-link');
    if (!installLink) return;

    const os = window.session?.browser?.os;
    if (os === "Mac") {
      installLink.href = installLink.href.replace('/install', '/install/mac');
    } else if (os === "Windows") {
      installLink.href = installLink.href.replace('/install', '/install/windows');
    } else if (os === "Linux") {
      installLink.href = installLink.href.replace('/install', '/install/linux');
    }
  }
}

var Print = {
  init: function() {
    Print.tagline = $("#tagline");
    Print.scrollToTop = $("#scrollToTop");
    window.matchMedia("print").addListener((mediaQueryList) => {
      Print.toggle(mediaQueryList.matches);
    });
  },
  toggle: function(enable) {
    if (enable) {
      Print.taglineBackup = Print.tagline.html();
      Print.tagline.html("--print-out");
      Print.scrollToTopDisplay = Print.scrollToTop.attr("display");
      Print.scrollToTop.attr("display", "none");
    } else {
      Print.tagline.html(Print.taglineBackup || "--as-git-as-it-gets");
      Print.scrollToTop.attr("display", Print.scrollToTopDisplay);
    }
  }
}
