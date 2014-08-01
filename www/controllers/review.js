define(['JBrowse/Browser']
, function (Browser) {

    var config = {
        containerID: 'genome',
        baseUrl: 'data/jbrowse/',
        refSeqs: 'data/jbrowse/seq/refSeqs.json',
        include: ['data/jbrowse/trackList.json', 'data/jbrowse/edit-track.json', 'data/jbrowse/simple-track.json'],
        show_nav: false,
        show_tracklist: true,
        show_overview:  false,
        stores: {
            url: {
                type: "JBrowse/Store/SeqFeature/FromConfig",
                features: []
            }
        }
    };

    return ['$http', '$q', '$cookieStore', '$location', function (http, q, cookie, location) {
        this.browser = new Browser(config);

        this.sidebar_visible = true;
        this.toggle_sidebar  = function () {
            this.sidebar_visible = !this.sidebar_visible;
            var thisB = this.browser;
            setTimeout(function () {
                thisB.browserWidget.resize({w: $('#genome').width()});
            }, 0);
        };

        this.load = function (task) {
            console.log(task.tracks);
            task.tracks.push('simple_feature')
            task.tracks.reverse();
            console.log(task.tracks);
            this.browser.showRegion(task);
        };

        this.edits = function () {
            return this.browser.getEditTrack().store.features;
        };

        this.clear_edits = function () {
            this.browser.getEditTrack().store.features = {};
        };

        var jbrowse = this;

        var get = function () {
            return http.get('data/tasks/next?type=review')
            .then(function (response) {
                return response.data;
            })
            .then(function (task) {
                cookie.put('task', task);
                return task;
            });
        };

        var put = function (id, submission) {
            _.each(_.values(submission), function (f) {
                f.set('ref', f.get('seq_id'));
            });
            var data = JSON.stringify(submission, function (key, value) {
                if (key === '_parent' && value) {
                    return value.id();
                }
                else {
                    return value;
                }
            });
            return http.post('data/tasks/' + id, data).then(function (response) {
                console.log('saved submission');
            });
            // what on failure?
        }

        this.done = function () {
            var task = cookie.get('task');
            put(task.id, jbrowse.edits())
            .then(function () {
                cookie.remove('task');
                $('#thanks').modal();
            });
        };

        this.contribute_more = function () {
            var handler = function () {
                console.log('contribute more');
                jbrowse.clear_edits();
                get()
                .then(function (task) {
                    jbrowse.load(task);
                });
                $(this).off('hidden.bs.modal', handler);
            };
            $('#thanks').modal('hide').on('hidden.bs.modal', handler);
        };

        this.go_back_to_dashboard = function () {
            var scope = this;
            var handler = function () {
                scope.$apply(function () {
                    location.path('/');
                });
                $(this).off('hidden.bs.modal', handler);
            };
            $('#thanks').modal('hide').on('hidden.bs.modal', handler);
        }

        // initialize
        q.when(cookie.get('task'))
        .then(function (task) {
            return task || get();
        })
        .then(function (task) {
            jbrowse.load(task);
        });
    }];
});
