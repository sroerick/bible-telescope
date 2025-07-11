# 📖 nvim-bible

A Neovim Telescope extension for exploring the Bible with Strong’s Concordance references — fully offline and Markdown-based.

---

## ✨ Features

- Browse books, chapters, and verses using Telescope
- Lookup verses directly (e.g. `John 3:16-18`)
- View chapters in read-only, concealed mode (Strong’s numbers are hidden)
- Hover over `[[H7225]]` or `[[G3056]]` and press `K` to see the Strong’s definition in a floating window
- Designed to work entirely offline with local `.md` Bible and lexicon files

---

## 📦 Installation

### With [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "yourusername/nvim-bible",
  dependencies = { "nvim-telescope/telescope.nvim" },
  config = function()
    require("telescope").load_extension("bible")
  end,
}

## Usage
Commands

    :Telescope bible — Browse all books

    :Telescope bible lookup — Search and insert specific verses (e.g., John 3:16-18)

Hover Support

    While viewing a chapter, place your cursor over a [[H####]] or [[G####]] tag

    Press K to open a floating window showing the Strong’s definition from your local concordance

You can use this version of the Bible for source Markdown files.
🛠 Configuration Ideas (coming soon)

In future versions you’ll be able to customize:

    Path to Bible and lexicon files

    Whether to conceal or show Strong’s numbers

    Whether chapter views open vertically, horizontally, or in the current window

## License

MIT — do what you want, but if you make something cool with it, tell me!
## Credits

    Telescope.nvim

    The Berean Study Bible with Strong’s links
