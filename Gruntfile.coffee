"use strict"

module.exports = (grunt) ->

    init = (params) ->
        # Load grunt tasks automatically
        require("load-grunt-tasks") grunt

        # Time how long tasks take. Can help when optimizing build times
        require("time-grunt") grunt

        grunt.initConfig

            # Project settings
            conf:
                # configurable paths
                module: "src"
                dist:   "dist"

            # Watches files for changes and runs tasks based on the changed files
            watch:
                coffee:
                    files: ["<%= conf.module %>/{,*/}*.{coffee,litcoffee,coffee.md}"]
                    tasks: ["newer:coffee:dist"]

                coffeeTest:
                    files: ["test/{,*/}*.{coffee,litcoffee,coffee.md}"]
                    tasks: [
                        "newer:coffee:test"
                        "karma"
                    ]

                gruntfile:
                    files: ["Gruntfile.coffee"]


            coffeelint:
                options:
                    configFile: "coffeelint.json"


            clean:
                dist:
                    files: [
                        dot: true
                        src: [
                            "<%= conf.dist %>/*"
                            "!<%= conf.dist %>/.git*"
                        ]
                    ]

            # Compiles CoffeeScript to JavaScript
            coffee:
                options:
                    sourceMap: false
                    sourceRoot: ""

                dist:
                    files: [
                        expand: true
                        cwd: "<%= conf.module %>"
                        src: "{,*/}*.coffee"
                        dest: "<%= conf.dist %>"
                        ext: ".js"
                    ]

                test:
                    files: [
                        expand: true
                        cwd: "test/spec"
                        src: "{,*/}*.coffee"
                        dest: "test/spec"
                        ext: ".js"
                    ]


            # ngmin tries to make the code safe for minification automatically by
            # using the Angular long form for dependency injection. It doesn't work on
            # things like resolve or inject so those have to be done manually.
            ngmin:
                dist:
                    files: [
                        expand: true
                        cwd: "<%= conf.dist %>"
                        src: "*.js"
                        dest: "<%= conf.dist %>"
                    ]



            uglify:
                build:
                    files: [
                        expand: true
                        cwd: '<%= conf.dist %>'
                        src: '*.js'
                        dest: '<%= conf.dist %>'
                        ext: '.min.js'
                    ]

            karma:
                unit:
                    configFile: 'karma.conf.js'
                    singleRun: true


        grunt.registerTask "test", [
            "clean"
            "coffeelint"
            "coffee:dist"
            "coffee:test"
            "karma"
        ]
        grunt.registerTask "default", [
            "clean"
            "coffeelint"
            "coffee:dist"
            "ngmin:dist"
            "uglify:build"
        ]
        return

    init {} #initialize here for defaults (init may be called again later within a task)
    return