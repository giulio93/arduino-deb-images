#!/bin/bash

# The "Headset" UCM device (Qualcomm/qcm2290/Headphones.conf) sets
# TX_DEC0 Volume to 80 (-4dB) as part of its EnableSequence, but
# WirePlumber's ALSA integration only applies the "HiFi" verb's own
# EnableSequence -- it never triggers the per-device (Headset)
# EnableSequence. TX_DEC0 Volume is therefore left at whatever
# alsa-restore.service restores from /var/lib/alsa/asound.state (124,
# +40dB, on shipped boards), which clips the mic signal into unusable
# noise instead of a clean capture. Force it here to the value UCM
# already declares as correct. Must run after alsa-restore.service or
# it gets immediately overwritten back to the persisted state.

logger -t headset-mic-gain-fixup "Setting TX_DEC0 Volume to UCM-intended value (80)"
amixer -c 0 cset name='TX_DEC0 Volume' 80
