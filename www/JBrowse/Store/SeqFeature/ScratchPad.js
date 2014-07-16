define(['dojo/_base/declare', 'JBrowse/Store/SeqFeature', 'JBrowse/Model/SimpleFeature']
, function (declare, SeqFeatureStore, SimpleFeature) {

    return declare (SeqFeatureStore, {

        constructor: function( args ) {
            this.refSeq = args.refSeq;
            this.features = {};
            this.sorted_feats = [];
            this._calculateStats();
        },

        insert: function (feature) {
            this.features[feature.id()] = feature;
            this._calculateStats();
        },

        replace: function (feature) {
            this.features[feature.id()] = feature;
            this._calculateStats();
        },

        deleteFeatureById: function (id) {
            delete  this.features[id];
            this._calculateStats();
        },

        /* if feature with given id is present in store, return it.  Otherwise return null */
        getFeatureById: function (id )  {
            return this.features[id];
        },

        _calculateStats: function () {
            var minStart = Infinity;
            var maxEnd = -Infinity;
            var featureCount = 0;
            for (var id in this.features) {
                var f = this.features[id];
                var s = f.get('start');
                var e = f.get('end');
                if( s < minStart )
                    minStart = s;

                if (e > maxEnd)
                    maxEnd = e;

                featureCount++;
            }

            this.globalStats = {
                featureDensity: featureCount/(this.refSeq.end - this.refSeq.start +1), 
                featureCount: featureCount,
                minStart: minStart, /* 5'-most feature start */
                maxEnd: maxEnd,     /* 3'-most feature end */
                span: (maxEnd-minStart+1)  /* min span containing all features */
            };
        },

        getFeatures: function (query, featCallback, endCallback, errorCallback) {
            var start = query.start;
            var end = query.end;
            if (Object.keys(this.features).length == 0) {
                var url = '/data/task/' + this.browser.task_id + '/submissions';
                $.getJSON(url, _.bind(function (features) {
                    for (var i = 0; i < features.length; i++) {
                        var feature = new SimpleFeature({id: features[i].id, data: features[i]});
                        this.insert(feature);
                        featCallback(feature);
                    }
                }, this));
            }
            else {
                for (var id in this.features) {
                    var f = this.features[id];
                    if (! (f.get('end') < start  || f.get('start') > end)) {
                        featCallback (f);
                    }
                }
            }
            if (endCallback)  { endCallback() }
        }
    });
});
