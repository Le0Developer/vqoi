module vqoi

import encoding.binary

// "qoif"
const magic_header = [byte(113), 111, 105, 102]


pub struct ImageMetadata {
pub mut:
	width  u32
	height u32
	channels   Channel
	colorspace ColorSpace
}

pub fn (img ImageMetadata) as_header() []byte {
	mut data := []byte{}
	data << magic_header

	mut temp := []byte{len: 4}
	binary.big_endian_put_u32(mut temp, img.width)
	data << temp
	binary.big_endian_put_u32(mut temp, img.height)
	data << temp

	data << byte(img.channels)
	data << byte(img.colorspace)

	return data
}


pub fn metadata_from_header(data []byte) ?ImageMetadata {
	for i, value in magic_header {
		if data[i] != value {
			return error('image is missing magic header bytes')
		}
	}
	width := binary.big_endian_u32(data[4..8])
	height := binary.big_endian_u32(data[8..12])

	channels := data[12]
	colorspace := data[13]

	if channels != 3 && channels != 4 {
		return error('only supports channels 3 or 4, not $channels')
	}
	if colorspace != 0 && colorspace != 1 {
		return error('only supports colorspaces 0 or 1, not $colorspace')
	}

	return ImageMetadata{width, height, Channel(channels), ColorSpace(colorspace)}
}

pub enum Channel {
	rgb = 3
	rgba = 4
}

pub enum ColorSpace {
	srgb = 0
	linear = 1
}
