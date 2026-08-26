#!/usr/bin/env bash
set -euo pipefail

# convert.sh — spain-demographic-dynamics-map
#
# Builds a single population_variation.pmtiles containing all 4 layers
# (ccaa, provincia, comarca, municipio), each visible only within its own
# zoom range. Run this inside WSL/Ubuntu — tippecanoe has no native Windows
# build (see R3.1 "The Death of the Tile Server" / R3.3 flag reference).
#
# data/raw/       = original source files (gpkg, padrón CSV)
# data/processed/ = the 4 GeoJSON layers produced by 00_build_population_geojson_layers.ipynb
# data/derived/   = the .pmtiles built here, and everything created from this
#                    point onward in the pipeline
#
# This project folder IS the repo root — no copying between folders needed.
#
# Zoom ranges below are a first pass, not final — we'll retune them once the
# map is actually rendering in the browser (next step: index.html).

INPUT_DIR="data/processed"
OUTPUT_DIR="data/derived"
OUTPUT="$OUTPUT_DIR/population_variation.pmtiles"

mkdir -p "$OUTPUT_DIR"

# fid = real INE administrative code per layer (Mun_Code / Comarca_Code /
# Prov_Code / CCAA_Code, all cast to int in the notebook) -- tippecanoe
# needs a numeric attribute to promote to a tile feature id, and these
# codes are guaranteed unique per layer.
tippecanoe \
  -o "$OUTPUT" \
  -f \
  -z10 \
  --detect-shared-borders \
  --coalesce-densest-as-needed \
  --drop-densest-as-needed \
  --simplification=2 \
  --use-attribute-for-id=fid \
  -L '{"file":"'"$INPUT_DIR"'/ccaa.geojson","layer":"ccaa","minzoom":4,"maxzoom":5}' \
  -L '{"file":"'"$INPUT_DIR"'/provincia.geojson","layer":"provincia","minzoom":4,"maxzoom":6}' \
  -L '{"file":"'"$INPUT_DIR"'/comarca.geojson","layer":"comarca","minzoom":5,"maxzoom":7}' \
  -L '{"file":"'"$INPUT_DIR"'/municipio.geojson","layer":"municipio","minzoom":6,"maxzoom":10}'

echo ""
echo "=== Build complete: $OUTPUT ==="
ls -la "$OUTPUT"

if command -v pmtiles &> /dev/null; then
  echo ""
  echo "=== pmtiles show ==="
  pmtiles show "$OUTPUT"
else
  echo ""
  echo "(pmtiles CLI not found — skipping 'pmtiles show'. Install it to inspect layers/zoom/size:"
  echo " https://github.com/protomaps/go-pmtiles/releases)"
fi
