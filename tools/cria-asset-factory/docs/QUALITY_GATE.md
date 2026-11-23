# Gate

Run from the official root: `python tools/cria-asset-factory/scripts/quality_gate.py` (10 JSONs + index + palette/style + duplicate runtime guard). With a licensed candidate directory, use `--candidate /absolute/path` to verify optional PNG pixels, sidecars, pivot and sync_map. Local PASS is **candidate-only**, never shipping. After a separate scene integration, human QA and `npm run quality` are required.
