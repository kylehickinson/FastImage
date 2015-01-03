# FastImage

FastImage is an Objective-C port of the [Ruby project by Stephen Sykes](https://github.com/sdsykes/fastimage). It's directive is to request as little data as possible (usually just the first batch of bytes returned by a request) to determine the size and type of a remote image.

This means you can get the size of a large image (say 2MB), by only downloading around 8KB - 32KB

Fairly simple to use:

```
KHIFastImage *fastImage = [[KHIFastImage alloc] init];
NSURL *imageURL = [NSURL URLWithString:@"http://i.imgur.com/7GLI90s.jpg"];

[fastImage imageSizeAndTypeForURL:imageURL completion:^(CGSize size, KHIFastImageType type, NSError *error) {
  // Size will be 1600 x 1200
  // Type would be JPEG
  // This example only downloads 892 bytes to get the size (first block returned by NSURLSessionDataTask)
}
```

Currently supports **JPEG**, **PNG**, **BMP**, and **GIF**. Possible future support for other formats like TIFF, ICO, etc.  

## Compatability

Tested with iOS 7 upwards, Xcode 6.1 and ARC. Could probably be usable on OS X with a few tweaks

## License

MIT, see LICENSE file