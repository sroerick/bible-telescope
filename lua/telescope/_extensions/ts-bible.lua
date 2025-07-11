local telescope = require("telescope")
local bible = require("ts-bible").pick_books
local insert = require("ts-bible").lookup_verses

return telescope.register_extension({
  setup = function(_) end,  -- no-op config
  exports = {
    bible = bible,
    insert = insert,
  },
})

