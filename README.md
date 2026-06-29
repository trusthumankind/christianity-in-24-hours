# Christianity Reconstructed in 24 Hours

This living book (meaning never finished, always being challenged and refined) is modeled after the [Sams Teach Yourself][1] series, with the belief that Christianity shouldn't require a master's degree to understand.

In fact, over the course of 24 hours, you can come to have a functionally complete knowledge of Christianity. From there, you can make a very informed decision on whether to embrace Christianity as your faith.

Yes, the Bible—sometimes called the "word of God"—is extremely verbose and at times difficult to interpret in today's language. But God's will is actually quite simple, and you should be wary of anyone who tries to tell you otherwise.

In fact, Jesus is pretty blunt about God's commandments.

> You shall love the Lord your God with all your heart and with all your soul and with all your mind. This is the great and first commandment. And a second is like it: You shall love your neighbor as yourself. On these two commandments depend all the Law and the Prophets.
— [Matthew 22:37-40 ESV][2]

Know that some people practice [willful ignorance][3].
- At best, they don't want to confront inconvenient truths.
- At worst, they want to manipulate others for personal gain.

But this book is a question for _you_, not someone else, just _you_.

Ready for a shot of the truth? Straight, no chaser? Then let's go!

[1]: http://www.informit.com/imprint/series_detail.aspx?st=61327
[2]: https://www.esv.org/Matthew+22/
[3]: http://themelios.thegospelcoalition.org/article/the-art-of-imperious-ignorance

## Style guide

See [STYLE.md](STYLE.md) for voice, tone, and editorial conventions.

## Building the EPUB

### Prerequisites

```bash
brew install pandoc epubcheck librsvg
pip3 install Pillow
```

### Build

```bash
bash scripts/build-epub.sh christianity-in-24-hours.epub
```

The build script handles everything: manuscript prep (stripping website nav links), cover generation, pandoc build, post-processing (removing pandoc's auto-generated title page, nesting Hours under Parts in the TOC, setting start-reading position), repackaging, and epubcheck validation.

### Cover image (uploaded separately to KDP)

```bash
rsvg-convert -w 1600 -h 2560 assets/covers/concept-b-revised.svg | \
  python3 -c "from PIL import Image; import sys; \
  Image.open(sys.stdin.buffer).convert('RGB').save('cover-kdp.jpg','JPEG',quality=95)"
```

### Kindle conversion test

```bash
brew install --cask calibre
ebook-convert christianity-in-24-hours.epub book.azw3 --pretty-print
```

## How to contribute

Readers, ask your question or (respectfully) challenge existing content by creating an issue on [the Issues tab][4].

Writers, [create pull requests][5] following [Leanpub conventions][6]!

[4]: https://guides.github.com/features/issues/
[5]: https://opensource.guide/how-to-contribute/
[6]: https://leanpub.com/help/getting_started_sync_github
