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
    echo '</create></osmChange>') \
  | time curl -sSNT- -X POST -H 'content-type: text/xml' \
    http://localhost:54321/api/0.6/changeset/$changeset/upload \
    > /dev/null
