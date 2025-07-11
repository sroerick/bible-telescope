local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local bible_dir = debug.getinfo(1, "S").source:sub(2):match("(.*[/\\])") .. "./bible"


local function open_chapter_buffer(path)
  vim.cmd("vsplit " .. vim.fn.fnameescape(path))

  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].modifiable = false
  vim.bo[buf].readonly = true
  vim.bo[buf].buftype = ""

  -- Force filetype to markdown to ensure syntax highlights
  vim.api.nvim_buf_set_option(buf, "filetype", "markdown")
  vim.api.nvim_buf_set_option(buf, "conceallevel", 2)
  vim.api.nvim_buf_set_option(buf, "concealcursor", "n")
  vim.api.nvim_buf_set_option(buf, "wrap", false)


  -- Add conceal rule scoped to this buffer
  vim.api.nvim_buf_call(buf, function()
    vim.cmd([[syntax match StrongRef /\[\[H\d\+\]\]\|\[\[G\d\+\]\]/ conceal]])
  end)

  
  -- Force normal mode (in case we're still in insert mode from Telescope)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
end


-- 🗂 Get folders like "01 - Genesis"
local function get_books()
  local entries = vim.fn.globpath(bible_dir, "*", 0, 1)
  return vim.tbl_filter(function(path)
    return vim.fn.isdirectory(path) == 1
  end, entries)
end

-- 🔡 Strip "01 - " and just return "Genesis"
local function book_display(path)
  return path:match("%d+%s+%-+%s+(.*)") or vim.fn.fnamemodify(path, ":t")
end

-- 📖 Map of simplified book names to folder paths
local book_name_map = {}
for _, path in ipairs(get_books()) do
  local name = path:match("%d+%s+%-+%s+(.*)")
  if name then
    local simplified = name:lower():gsub("%W+", "")
    book_name_map[simplified] = path
  end
end

local function clean_verse_text(text)
  -- Remove any [[...]] tags like [[H7225]], [[G3056]], [[123]], etc.
  local cleaned = text:gsub("%[%[%a?%d+%]%]", "")
  cleaned = cleaned:gsub("%s+", " ")
  return cleaned:match("^%s*(.-)%s*$")
end

local function parse_verses(chapter_path)
  local lines = vim.fn.readfile(chapter_path)
  local verses = {}

  for _, line in ipairs(lines) do
    local num, text = line:match("^(%d+)%s+(.*)")
    if num and text then
      text = clean_verse_text(text)
      table.insert(verses, { num = num, text = text })
    end
  end

  return verses
end

-- 📚 Try to match a fuzzy book name to its path
local function resolve_book_path(input)
  local normalized = input:lower():gsub("%W+", "")
  for key, val in pairs(book_name_map) do
    if key:find(normalized, 1, true) == 1 then
      return val
    end
  end
  return nil
end

local function show_strongs_popup()
  local word = vim.fn.expand("<cWORD>")
  local strongs_id = word:match("%[%[(H%d+)%]%]") or word:match("%[%[(G%d+)%]%]")
  if not strongs_id then
    print("No Strong's reference under cursor")
    return
  end

  local base_dir = debug.getinfo(1, "S").source:sub(2):match("(.*[/\\])") .. "./lexicon"
  local path = base_dir .. "/" .. strongs_id .. ".md"

  if vim.fn.filereadable(path) == 0 then
    print("Strong's entry not found: " .. strongs_id)
    return
  end

  local lines = vim.fn.readfile(path)

  -- Create floating window
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local width = math.floor(vim.o.columns * 0.6)
  local height = math.floor(vim.o.lines * 0.6)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "single"
  })
end


-- 🔎 Lookup and insert specific verse(s)
local function lookup_verses()
  vim.ui.input({ prompt = "Verse (e.g. John 3:16-18): " }, function(input)
    if not input then return end

    local book, chapter, vstart, vend

    -- Try range: "John 3:16-18"
    book, chapter, vstart, vend = input:match("^([^%d]+)%s+(%d+):(%d+)%s*%-%s*(%d+)$")

    -- Try single verse: "John 3:16"
    if not (book and chapter and vstart) then
      book, chapter, vstart = input:match("^([^%d]+)%s+(%d+):(%d+)$")
      vend = vstart
    end

    vend = vend or vstart
    if not (book and chapter and vstart and vend) then
      print("Invalid input. Use format: Book 3:16 or Book 3:16-18")
      return
    end

    local book_path = resolve_book_path(book)
    if not book_path then
      print("Could not resolve book: " .. book)
      return
    end

    local chapter_file = string.format("%s/%s %s.md", book_path, book_display(book_path), chapter)
    if vim.fn.filereadable(chapter_file) == 0 then
      print("Chapter file not found: " .. chapter_file)
      return
    end

    local all_verses = parse_verses(chapter_file)
    local filtered = {}
    for _, verse in ipairs(all_verses) do
      local num = tonumber(verse.num)
      if num and num >= tonumber(vstart) and num <= tonumber(vend) then
        table.insert(filtered, verse)
      end
    end

    if #filtered == 0 then
      print("No verses found in that range.")
      return
    end


    local original_win = vim.api.nvim_get_current_win()
    pickers.new({}, {
      prompt_title = string.format("%s %s:%s-%s", book, chapter, vstart, vend),
      finder = finders.new_table {
        results = filtered,
        entry_maker = function(entry)
          return {
            value = entry,
            display = entry.num .. ": " .. entry.text,
            ordinal = entry.text,
          }
        end
      },
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
            actions.close(prompt_bufnr)
            vim.api.nvim_set_current_win(original_win)

            local lines = {}
            for _, v in ipairs(filtered) do
                local citation = string.format("%s %s:%s — %s", book, chapter, v.num, clean_verse_text(v.text))
            table.insert(lines, citation)
            end
            vim.api.nvim_put(lines, "", true, true)
            end)
        map("i", "<C-y>", function()
          local lines = {}
          for _, v in ipairs(filtered) do
            table.insert(lines, v.num .. ": " .. v.text)
          end
          vim.fn.setreg('"', table.concat(lines, "\n"))
          print("Copied to unnamed register")
        end)

        return true
      end
    }):find()
  end)
end




-- 📄 Get .md chapter files from a book
local function get_chapters(book_path)
  return vim.fn.globpath(book_path, "*.md", 0, 1)
end


-- 🔽 Picker: Verses
local function pick_verses(chapter_path, book_label, chapter_label) local verses = parse_verses(chapter_path)
  pickers.new({}, {
    prompt_title = book_label .. " " .. chapter_label,
    finder = finders.new_table {
      results = verses,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry.num .. ": " .. entry.text,
          ordinal = entry.num .. " " .. entry.text,
        }
      end
    },
    sorter = conf.generic_sorter({}),
    attach_mappings = function(_, map)
      actions.select_default:replace(function()
        local entry = action_state.get_selected_entry()
        open_chapter_buffer(chapter_path)
      end)

      -- <C-x>: open full chapter in vertical split
      map("i", "<C-x>", function()
        open_chapter_buffer(chapter_path)
      end)
      map("n", "<C-x>", function()
        open_chapter_buffer(chapter_path)
      end)

      return true
    end,
  }):find()
end




-- 🔽 Picker: Chapters
local function pick_chapters(book_path)
  local book_label = book_display(book_path)
  local chapters = get_chapters(book_path)

  pickers.new({}, {
    prompt_title = "Chapters in " .. book_label,
    finder = finders.new_table {
      results = chapters,
      entry_maker = function(path)
        return {
          value = path,
          display = vim.fn.fnamemodify(path, ":t:r"), -- "Genesis 1"
          ordinal = path,
        }
      end,
    },
    sorter = conf.generic_sorter({}),
    attach_mappings = function(_, map)
      -- Default: drill into verses
      actions.select_default:replace(function()
        local entry = action_state.get_selected_entry()
        local chapter_label = vim.fn.fnamemodify(entry.value, ":t:r")
        pick_verses(entry.value, book_display(book_path), chapter_label)
      end)

      -- <C-x>: open full chapter in vertical split
      map("i", "<C-x>", function()
        local entry = action_state.get_selected_entry()
        vim.cmd("vsplit " .. vim.fn.fnameescape(entry.value))
      end)
      map("n", "<C-x>", function()
        local entry = action_state.get_selected_entry()
        vim.cmd("vsplit " .. vim.fn.fnameescape(entry.value))
      end)

      return true
    end,
  }):find()
end

-- 🔽 Picker: Books
local function pick_books()
  local books = get_books()

  pickers.new({}, {
    prompt_title = "Bible Books",
    finder = finders.new_table {
      results = books,
      entry_maker = function(path)
        return {
          value = path,
          display = book_display(path),
          ordinal = path,
        }
      end,
    },
    sorter = conf.generic_sorter({}),
    attach_mappings = function(_, _)
      actions.select_default:replace(function()
        local entry = action_state.get_selected_entry()
        pick_chapters(entry.value)
      end)
      return true
    end,
  }):find()
end


vim.keymap.set("n", "K", show_strongs_popup, { desc = "Show Strong's entry" })

-- 📦 Register as Telescope extension
return require("telescope").register_extension({
  exports = {
    bible = pick_books,
    lookup = lookup_verses,
  }
})



