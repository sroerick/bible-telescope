# 📖 nvim-bible

A Neovim Telescope extension for exploring the Bible with Strong’s Concordance references — fully offline and Markdown-based.

---

## ✨ Features

- Browse books, chapters, and verses using Telescope
- Insert Verses into 
- View chapters in read-only, concealed mode (Strong’s numbers are hidden)
- Hover over `[[H7225]]` or `[[G3056]]` and press `K` to see the Strong’s definition in a floating window
- Designed to work entirely offline with local `.md` Bible and lexicon files

---

## 📦 Installation

### With Pckr

```lua
{
  "sroerick/ts-bible",
  dependencies = { "nvim-telescope/telescope.nvim" },
  config = function()
    require("telescope").load_extension("ts-bible")
  end,
}

## Usage
Commands

    :Telescope ts-bible bible — Browse all books

    :Telescope bible insert — Search and insert specific verses (e.g., John 3:16-18)

Hover Support

    While viewing a chapter, place your cursor over a [[H####]] or [[G####]] tag

    Press K to open a floating window showing the Strong’s definition from your local concordance

## License

MIT — do what you want, but if you make something cool with it, tell me!


## Credits
    Telescope.nvim https://github.com/nvim-telescope/telescope.nvim
    The Berean Study Bible with Strong’s links - https://github.com/gapmiss/berean-study-bible-with-strongs
    iThe Holy Bible, Berean Standard Bible, BSB is produced in cooperation with Bible Hub, Discovery Bible, OpenBible.com, and the Berean Bible Translation Committee. This text of God's Word has been dedicated to the public domain.j
