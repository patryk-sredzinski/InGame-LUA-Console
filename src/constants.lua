-- Shared constants: settings, layout, colors, GUI element names.

local M = {
  PAD = 8,
  BTN_H = 28,
  SIDE_W = 250,

  -- Preview / import safety limits
  PREVIEW_MAX_LINES = 500,
  IMPORT_MAX_SCRIPTS = 200,
  IMPORT_MAX_CODE_LEN = 200000,
  IMPORT_MAX_RAW = 2500000,

  COLOR_ERR = { r = 1, g = 0.4, b = 0.4 },
  COLOR_OK = { r = 0.6, g = 1, b = 0.6 },

  -- legacy inventory-relative frame name (destroyed on load if present)
  BTN_FRAME = "ilc_button_frame",
  -- mod-gui top button
  BTN_TOP = "ilc_top_button",

  -- main window
  MAIN = "ilc_main",
  CLOSE = "ilc_close",
  MINMAX = "ilc_minmax",

  -- script list
  LIST = "ilc_list",
  SEARCH = "ilc_search",
  NEW = "ilc_new",
  LOAD = "ilc_load",
  LOAD_ICON = "ilc_load_icon",
  DELETE = "ilc_delete",

  -- editor
  EDIT = "ilc_edit",
  VIEW = "ilc_view",
  VIEW_LABEL = "ilc_view_label",
  MODE_BTN = "ilc_mode_btn",
  VALIDATE = "ilc_validate",
  HOTKEY_EXECUTE = "ilc_hotkey_execute",
  RUN = "ilc_run",
  SAVE = "ilc_save",

  -- save dialog
  SAVE_DLG = "ilc_save_dlg",
  SAVE_TITLE = "ilc_save_title",
  SAVE_ICON = "ilc_save_icon",
  SAVE_OK = "ilc_save_ok",
  SAVE_CANCEL = "ilc_save_cancel",

  -- import / export
  IO_BTN = "ilc_io",
  IO_DLG = "ilc_io_dlg",
  IO_TEXT = "ilc_io_text",
  IO_IMPORT = "ilc_io_import",
  IO_CLOSE = "ilc_io_close",

  -- confirm delete
  CONFIRM_DLG = "ilc_confirm_dlg",
  CONFIRM_YES = "ilc_confirm_yes",
  CONFIRM_NO = "ilc_confirm_no",

  -- error dialog
  ERR_DLG = "ilc_err_dlg",
  ERR_TEXT = "ilc_err_text",
  ERR_COPY = "ilc_err_copy",
  ERR_CLOSE = "ilc_err_close",
}

return M
