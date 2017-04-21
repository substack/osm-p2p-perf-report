# benchmark procedure

``` sh
$ rm -rf /tmp/osm-p2p-perf-test
$ osm-p2p-server -p 54321 -d /tmp/osm-p2p-perf-test
```

monitor the osm-p2p-server process for cpu (%), RSS and VSZ (kilobytes):

``` sh
#!/bin/bash
while true; do
  ps aux|grep osm-p2p-server|head -n1|awk '{print $3,$5,$6}'
  sleep 1
done | tee monitor.txt
```

generate a changeset from peermaps and upload it to osm-p2p-server:

``` sh
#!/bin/bash
export changeset=$(echo '<osm><changeset></changeset></osm>' \
  | curl -sSNT- -H 'content-type: text/xml' \
    http://localhost:54321/api/0.6/changeset/create)
(echo '<osmChange><create>'
    ipfs cat /ipfs/QmNPkqYfis1XV2CcAyE9ByttxGnvvtVJ4VfFXtbBWnd7fW/2/6/2/6.o5m.gz \
    | osmconvert - \
    | perl -pe's/changeset="(.*?)"/changeset="$ENV{changeset}"/;
      s/id="(.*?)"/$ids{$1}=-1-$i;q[id="-].(++$i).q["]/e;
      s/ref="(.*?)"/q[ref="].$ids{$1}.q["]/e' \
    | grep -vE '^\s*</?(osm|bounds|\?xml)' \
    | grep -v 'ref=""'
    echo '</create></osmChange>') > /tmp/changeset.xml
  time curl -m 9999 -sSNT /tmp/changeset.xml -X POST -H 'content-type: text/xml' \
    http://localhost:54321/api/0.6/changeset/$changeset/upload \
    > /dev/null
```

The changeset file is 18M:

```
$ ls -sh /tmp/changeset.xml 
18M /tmp/changeset.xml
```

# results

## current

For this test, osm-p2p-db with all the current settings was used.

The configuration in `osm-p2p-server/bin/cmd.js` was:

``` js
var osmdb = require('osm-p2p')
var osm = osmdb(argv.datadir)
```

```
$ scripts/perf.sh 

real  2m50.673s
user  0m1.140s
sys 0m2.404s
```

The memory usage peaks at 1049912 kb RSS then drops back to a steady 325684. The
CPU usage remains high as the indexes catch up. The CPU slowly declined from
over 100% but remained high. When the monitoring was stopped the process was
still taking 77% of a CPU. Presumably the indexes were still catching up.

## memdb

For this test, the leveldb instances were swapped with memdb.

The configuration in `osm-p2p-server/bin/cmd.js` was:

``` js
var osmdb = require('osm-p2p-db')
var memdb = require('memdb')
var hyperlog = require('hyperlog')
var fdstore = require('fd-chunk-store')
var osm = osmdb({
  log: hyperlog(memdb(), { valueEncoding: 'json' }),
  db: memdb(),
  store: fdstore(4096, path.join(argv.datadir,'kdb'))
})
```

```
$ scripts/perf.sh 

real  2m48.194s
user  0m1.100s
sys 0m2.336s
```

Surprisingly, using memdb takes about the same amount of time. The CPU stays
lower than the unmodified version but memory usage is higher and stays high, as
expected.

## memory-chunk-store

For this test, the fdstore was swapped with an in-memory replacement,
memory-chunk-store. The leveldb configuration is the same as the current stock
version.

The configuration in `osm-p2p-server/bin/cmd.js` was:

``` js
var level = require('level')
var hyperlog = require('hyperlog')
var memstore = require('memory-chunk-store')
var osm = osmdb({
  log: hyperlog(level(path.join(argv.datadir,'log')), { valueEncoding: 'json' }),
  db: level(path.join(argv.datadir,'index')),
  store: memstore(4096)
})
```

```
$ scripts/perf.sh 

real  2m48.109s
user  0m1.236s
sys 0m2.376s
```

Also surprisingly, the time is about the same as using fd-chunk-store and the
CPU usage remains high afterward.

