module.exports = function(grunt) {

  grunt.initConfig({
    // Project configuration.
    pkg: grunt.file.readJSON('package.json'),

    // Handle vendor prefixing
    autoprefixer: {
      options: {
        browsers: ['last 2 versions', 'ie 8', 'ie 9']
      },
      dist: {
        src: 'css/*.css'
      },
    },

    // Runs CSS reporting
    parker: {
      options: {
        metrics: [
          'TotalStylesheets',
          'TotalStylesheetSize',
          'TotalRules',
          'TotalSelectors',
          'TotalIdentifiers',
          'TotalDeclarations',
          'SelectorsPerRule',
          'IdentifiersPerSelector',
          'SpecificityPerSelector',
          'TopSelectorSpecificity',
          'TopSelectorSpecificitySelector',
          'TotalIdSelectors',
          'TotalUniqueColours',
          'TotalImportantKeywords',
          'TotalMediaQueries'
        ],
        file: "doc/css-stats.md",
        usePackage: true
      },
      src: [
        'tmp/css/git-scm.css'
      ],
    },

    stylelint: {
      all: ['app/assets/**/*.scss']
    }
  });

  // Load dependencies
  grunt.loadNpmTasks('grunt-autoprefixer');
  grunt.loadNpmTasks('grunt-parker');
  grunt.loadNpmTasks('grunt-stylelint');

  // Generate and format the CSS
  grunt.registerTask('default', ['stylelint', 'autoprefixer', 'parker']);
};
