# Wave Link

`config.json` holds every mix, channel, route and effect setting (plugin state is embedded).
`make nix` seeds it on a Mac that has no Wave Link config yet; after that, sync by hand:

- `wavelink backup` - copy the live config into the repo, then commit.
- `wavelink restore` - quit Wave Link, copy the repo config over the live one, relaunch.

The mic channel is bound to the Scarlett 6i6 (serial 00079550). On a Mac with other hardware,
re-add the mic channel and its effects.

## Plugins

Audio Unit plugins are licensed Marketplace downloads (~255 MB), so they stay out of git.
Install them from Wave Link → Marketplace → Audio effects; `make nix` lists any that are missing.

| Plugin | Vendor | Role |
|---|---|---|
| MONOCORE | makrofon | Input 1 to both ears |
| Elgato Noise Removal | Elgato | Noise removal + gate |
| Elgato Compressor | Elgato | Compressor |
| Elgato Equalizer | Elgato | EQ (spare, NBandEQ is in use) |
| Elgato De-Esser | Elgato | De-esser (spare) |

## Volume keys

`conf/hammerspoon/init.lua` maps the keyboard volume keys to the Speakers/Headphones mix when
the output device has no volume of its own, and the mute key to the Scarlett Monitor 1-2 mute
(speakers only, headphones on Line 3-4 keep playing). Grant Hammerspoon Accessibility access once,
and approve the "q-hammerspoon" client in Focusrite Control once.
