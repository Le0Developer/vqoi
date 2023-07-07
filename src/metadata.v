module vqoi

import encoding.binary

// "qoif"
const magic_header = [u8(113), 111, 105, 102]

pub struct ImageMetadata {
pub mut:
	width      u32
	height     u32
	channels   Channel
	colorspace ColorSpace
}

pub fn (img ImageMetadata) as_header() []u8 {
	mut data := []u8{}
	data << magic_header

	mut temp := []u8{len: 4}
	binary.big_endian_put_u32(mut temp, img.width)
	data << temp
	binary.big_endian_put_u32(mut temp, img.height)
	data << temp

	data << u8(img.channels)
	data << u8(img.colorspace)

	return data
}

pub fn metadata_from_header(data []u8) !ImageMetadata {
	for i, value in magic_header {
		if data[i] != value {
			return error('image is missing magic header bytes')
		}
	}
	width := binary.big_endian_u32(data[4..8])
	height := binary.big_endian_u32(data[8..12])

	mut channels := Channel.rgb
	mut colorspace := ColorSpace.linear

	match data[12] {
		3 { channels = .rgb }
		4 { channels = .rgba }
		else { return error('only supports channels 3 or 4, not ${data[12]}') }
	}
	match data[13] {
		0 { colorspace = .srgb }
		1 { colorspace = .linear }
		else { return error('only supports colorspaces 0 or 1, not ${data[13]}') }
	}

	return ImageMetadata{width, height, channels, colorspace}
}

pub enum Channel {
	rgb = 3
	rgba = 4
}

pub enum ColorSpace {
	srgb = 0
	linear = 1
}
