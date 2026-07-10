#!/bin/bash

# The "Headset" UCM device (Qualcomm/qcm2290/Headphones.conf) declares
# TX_DEC0 Volume should be 80 (-4dB) as part of its EnableSequence, but
# WirePlumber's ALSA/ACP integration never applies that per-device UCM
# sequence -- and, confirmed on-device, WirePlumber's own startup resets
# TX_DEC0 Volume to 124 (+40dB) itself, independent of alsa-restore.service.
# This happens on *every* WirePlumber start, not just at boot -- including
# on-demand starts triggered by higher-level app orchestration -- which
# clips the mic signal into unusable noise instead of a clean capture.
#
# Invoked via a systemd user drop-in on wireplumber.service
# (ExecStartPost=). ExecStartPost fires as soon as the process launches,
# not once WirePlumber has actually finished its own internal ALSA/ACP
# profile activation -- confirmed on-device that a single immediate
# cset here can lose the race against WirePlumber's own later reset.
# Reapply repeatedly for a few seconds after start so this always wins
# regardless of exactly when WirePlumber's internal reset happens.

logger -t headset-mic-gain-fixup "Forcing TX_DEC0 Volume to UCM-intended value (80) for 10s to win the race against WirePlumber's own reset"
for i in $(seq 1 20); do
	amixer -c 0 cset name='TX_DEC0 Volume' 80 >/dev/null 2>&1
	sleep 0.5
done
