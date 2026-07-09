#!/bin/bash

# The "Headset" UCM device (Qualcomm/qcm2290/Headphones.conf) declares
# TX_DEC0 Volume should be 80 (-4dB) as part of its EnableSequence, but
# WirePlumber's ALSA/ACP integration never applies that per-device UCM
# sequence -- and, confirmed on-device, WirePlumber's own startup resets
# TX_DEC0 Volume to 124 (+40dB) itself, independent of alsa-restore.service.
# This happens on *every* WirePlumber start, not just at boot -- including
# on-demand starts triggered by higher-level app orchestration -- which
# clips the mic signal into unusable noise instead of a clean capture.
# Invoked via a systemd user drop-in on wireplumber.service
# (ExecStartPost=) rather than a one-shot boot service, since a boot-time
# fix alone does not survive a later WirePlumber restart.

logger -t headset-mic-gain-fixup "Setting TX_DEC0 Volume to UCM-intended value (80)"
amixer -c 0 cset name='TX_DEC0 Volume' 80
