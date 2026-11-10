-- InGame LUA Console — control entry point.
-- Logic lives in src/*; this file only boots event registration.

require("src.events").register()
