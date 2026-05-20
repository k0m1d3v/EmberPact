# Tileset · come usarlo in Godot 4

## 1. Import override (per ogni PNG)
Selezionate il file in FileSystem → tab Import:
- Filter: **Nearest** (no smoothing su pixel art)
- Mipmaps: **off**
- Re-Import

## 2. TileSet resource
Le 6 tile base (16×16) sono già unite in `tiles/tileset_atlas.png` — strip orizzontale, 6 colonne × 1 riga:

| Col | Tile                | Source ID |
|-----|---------------------|-----------|
| 0   | Erba                | 0         |
| 1   | Sentiero            | 1         |
| 2   | Acqua               | 2         |
| 3   | Roccia              | 3         |
| 4   | Ingresso dungeon    | 4         |
| 5   | Albero (top 16×16)  | 5         |

In Godot:
1. Crea un nuovo **TileSet** → aggiungi **Atlas Source** → assegna `tileset_atlas.png`
2. Imposta **Texture Region Size** = (16, 16)
3. Clicca "Setup" → "Create tiles in non-transparent regions"
4. Per l'albero usa `tile_tree.png` (16×32) come **scene tile** o sprite separato — occupa 2 tile in altezza
5. Acqua: aggiungi un **Animation** sulla tile (Y offsets, 4 frame) se vuoi l'effetto onda

## 3. Sprite pickup / nemici
Usa `Sprite2D` con texture = PNG. Tile a 16×16 = un tile in mappa.
