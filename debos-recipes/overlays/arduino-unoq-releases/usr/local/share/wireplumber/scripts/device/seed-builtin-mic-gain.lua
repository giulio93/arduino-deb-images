-- The board's built-in mic (alsa_card.platform-sound) is capped by UCM at
-- TX_DEC0 Volume = 80 (Headphones.conf's CaptureVolume), but nothing in the
-- UCM/ALSA/WirePlumber startup path actually applies that value: WirePlumber's
-- own device/apply-routes.lua always seeds an unset route's channelVolumes
-- from the global "device.routes.default-source-volume" setting (default
-- 1.0 = hardware max = clipped/noisy mic), and it does this as part of the
-- same step that triggers ACP to enable the UCM device -- there is no point
-- in the hook chain where UCM's declared value is live and not yet
-- overwritten, so it can't be read back dynamically.
--
-- This seeds the correct value directly, scoped to just this one device,
-- instead of overriding the global default setting (which would also wrongly
-- apply to any future USB mic plugged into the board).
--
-- 0.006331 is WirePlumber's internal linear-amplitude value that maps to
-- this control's raw hardware value 80 (found empirically via wpctl
-- set-volume), matching UCM's declared CaptureVolume.

devinfo = require ("device-info-cache")
log = Log.open_topic ("s-device")

local TARGET_DEVICE = "alsa_card.platform-sound"
local BUILTIN_MIC_GAIN = 0.006331

seed_builtin_mic_gain_hook = SimpleEventHook {
  name = "device/seed-builtin-mic-gain",
  after = "device/apply-route-props",
  before = "device/apply-routes",
  interests = {
    EventInterest {
      Constraint { "event.type", "=", "select-routes" },
    },
  },
  execute = function (event)
    local device = event:get_subject ()
    if device.properties ["device.name"] ~= TARGET_DEVICE then
      return
    end

    local selected_routes = event:get_data ("selected-routes")
    if not selected_routes then
      return
    end

    local dev_info = devinfo:get_device_info (device)
    if not dev_info then
      return
    end

    for device_id, route in pairs (selected_routes) do
      route = Json.Raw (route):parse ()
      route.props = route.props or {}

      local route_info = dev_info.route_infos [route.index]

      if route_info and route_info.direction == "Input" and not route.props.channelVolumes then
        log:info (device, "seed-builtin-mic-gain: seeding channelVolumes = "
          .. tostring (BUILTIN_MIC_GAIN) .. " for route index " .. tostring (route.index))
        route.props.channelVolumes = Json.Array ({ BUILTIN_MIC_GAIN })
        route.props = Json.Object (route.props)
        selected_routes [device_id] = Json.Object (route):to_string ()
      end
    end

    event:set_data ("selected-routes", selected_routes)
  end
}
seed_builtin_mic_gain_hook:register ()
