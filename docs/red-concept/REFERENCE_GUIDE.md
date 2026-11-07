# How to use this pack

Extract this directory into the ridingHood repository as `docs/red-concept/`. You should then have `docs/red-concept/PROMPT.md` and the three PNGs under `docs/red-concept/references/`.

Ask your coding agent:

> Read docs/red-concept/PROMPT.md and implement it in this repository. Before coding, open all three PNGs in docs/red-concept/references/ and read REFERENCE_GUIDE.md. Treat the images as visual direction and the prompt as the authority for mechanics. Build and verify the playable prototype.

If your agent accepts image attachments, attach the three PNGs to the same message as well. A path gives an agent access to a file, but it must use an image viewer or image-input feature to see the pixels. If its model or environment cannot view local images, attach them in a vision-capable interface or use the descriptions below. ChatGPT conversation links and sandbox links are not portable local assets for another coding agent; use the downloaded files.

## Reference 01 — bridge gameplay

File: references/01-bridge-gameplay.png

An aspirational side-view encounter. Red rides an ivory feather updraft beside a mossy bridge. A huntsman stands on the far side, a branch forms an upper route, and a tunnel suggests a lower route. Blue-green forest layers contrast with warm lamps and red accents. Three parchment cards sit on a dark shelf along the bottom.

Borrow: palette, small character within substantial scenery, distinct route heights, forest depth, tactile cards, the visual connection between a played card and its world effect.

Adjust: simplify the scenery, reserve UI space, reduce card size, and ensure physically playable geometry. The prototype uses FEATHER, STEP, BRIAR, not the depicted FEATHER, THREAD, BRIAR. A huntsman enemy is not required for the prototype.

## Reference 02 — light/dark card faces

File: references/02-light-dark-cards.png

Six illustrated cards in two rows. Light faces are parchment and warm gold; dark faces are violet, lilac, and black. Feather, thread, and briar motifs have benign and sinister meanings. Red and purple hooded characters flank the rows.

Borrow: illustrated-object symbolism, border language, typography hierarchy, and restrained contrast between the two palettes.

Do not implement the six pictured abilities. Those belong to an earlier unvalidated idea. The first playable prototype has three stable powers. Dark styling must not imply different abilities.

## Reference 03 — transformation

File: references/03-transformation.png

Red changes into a purple hooded character in a huge hollow tree with amber windows. Ivory feather particles turn into violet shadow, while the hand appears to flip from parchment to dark faces. Mossy ledges and thorny growth provide the scene structure.

Borrow: shared palette between character and UI, a short readable change effect, warm/cool lighting, and the fairy-tale atmosphere.

Adjust: make the effect short and nonblocking, avoid the giant central overlay, and preserve readable geometry. The existing game sprites are authoritative for the character. In this first prototype, transformation is cosmetic and card powers remain unchanged.

## What this pack is

These are AI-generated concept images from our design discussion, packaged as visual references. They are not production sprites, a level collision map, an exact game UI, or proof that the proposed mechanics work. The implementation should be evaluated by playing it.
