# FastImage 
[![Build Status](https://travis-ci.org/kylehickinson/FastImage.svg)](https://travis-ci.org/kylehickinson/FastImage)

FastImage 2.0 is an Swift port of the [Ruby project by Stephen Sykes](https://github.com/sdsykes/fastimage). It's directive is to request as little data as possible (usually just the first batch of bytes returned by a request) to determine the size and type of a remote image.

This means you can get the size of a large image (say 2MB), by only downloading around 8KB - 32KB

Fairly simple to use:

```
let fastImage = FastImage()
let imageURL = URL("http://i.imgur.com/7GLI90s.jpg")!

fastImage.imageSizeAndType(for: url, completion: { result in
  switch result {
  case .success(let (size, type)):
    // `size` would be 1600 x 1200
    // `type` would be .jpg
    ...
  case .failure(let error):
    // Get a URLError here (timed out, etc.) or a SizeNotFoundError (just couldn't get a size based on data)
  }
})
```

Currently supports **JPEG**, **PNG**, **BMP**, **GIF**, **TIFF**, **ICO**, **CUR**, and **PSD**.

## Compatability

2.0 was built with Xcode 10.1 with a deployment target of 11.0 but could likely be set lower

## License

MIT, see LICENSE file
