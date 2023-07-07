
# vqoi

[QOI](https://qoiformat.org/) imlementation in pure V.

> QOI is fast. It losslessy compresses images to a similar size of PNG, while offering 20x-50x faster encoding and 3x-4x faster decoding.
> 
> QOI is simple. The reference en-/decoder fits in about 300 lines of C. The file format specification is a single page PDF.

## Usage

```v
import vqoi
import os

fn main() {
	width := 500
	height := 400
	rgba := [][4]u8{len: width * height, init: [u8(255), 0, 0, 255]!}
	metadata := vqoi.ImageMetadata{u32(width), u32(height), .rgba, .srgb}
	image := vqoi.Image{rgba, metadata}
	data := vqoi.encode(image)
	os.write_file('hello.qoi', data.bytestr()) !

	decoded_image := vqoi.decode(data) !
	assert decoded_image == image
}
```
