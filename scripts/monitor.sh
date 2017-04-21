#!/bin/bash
while true; do
  ps aux|grep osm-p2p-server|head -n1|awk '{print $3,$5,$6}'
  sleep 5
done | tee monitor.txt
