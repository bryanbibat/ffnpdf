# FFNPDF

Just scratched an coding itch I've had for quite some time.

This gem scrapes stories from FanFiction.net and generates LaTeX PDFs. Polished turds, anyone?

## Installation

Ruby hackers already know how to install this stupid gem. But for everyone else, here's how to install it in Ubuntu.

First install [Ruby](http://www.ruby-lang.org). I'm guessing the gem won't work with ruby 1.8 so you'll need to install ruby 1.9:

    sudo apt-get install ruby1.9.1 ruby1.9.1-dev build-essential libxml2 libxml2-dev libxslt1-dev
    
Then install the gem via `gem install`:

    sudo gem install ffnpdf

It also requires [pandoc](http://johnmacfarlane.net/pandoc/) as well as a bunch of extra stuff related to LaTeX/XeTeX. In Ubuntu, you can install this using the following command:

    sudo apt-get install pandoc texlive-latex-extra texlive-xetex

It also uses [DejaVu Fonts](http://dejavu-fonts.org/wiki/Main_Page) as the default font. This font family is installed by default in Ubuntu.

## Usage

The basic command only requires the story's story ID.

    ffnpdf [STORY_ID]

This will scrape FFN for the story, convert the chapters into markdown, combine all chapters into a single file, and converts it into PDF, all inside the `STORY_ID` folder.

## Additional Commands

Since you may want to do your own edits to the fics (e.g. remove authors notes, correct chapter headers) there are additional commands that allow you to perform individual steps of the process.

### Pull

    ffnpdf pull [STORY_ID]

This command 

* creates the `STORY_ID` folder
* pulls chapters and converts them to Markdown
* creates template and variables (config) file

The markdown files are numbered from `0001.md` onwards. A title section, `0000.md`, is also created.

The `xetex.template` file is obviously the XeTeX template, while the `variables.txt` defines the [template variables section](http://johnmacfarlane.net/pandoc/README.html#general-writer-options) used when generating the PDF. Both can be modified to affect the result of running both `ffnpdf build` and `ffnpdf convert`.


### Build

    ffnpdf build [STORY_ID]

This command 

* combines all `.md` files to a single file, `combined.md`, in alphabetical order
* converts `combined.md` to `combined.pdf` while using both the template and variables file

### Convert

    ffnpdf convert [STORY_ID]

This command does only the second step of the Build i.e. converts `combined.md` to `combined.pdf`.

## Known Issues

**Page numbering in bookmark is incorrect for stories with long Table of Contents**

It's a tradeoff between wrong numbering in the Table of Contents or in the bookmarks. I chose the latter.

I still don't know the root cause, though.
