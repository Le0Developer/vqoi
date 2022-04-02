module vqoi

pub fn decode(data []byte) ?Image {
	if data.len < 14 {
		return error('missing header')
	}
	metadata := metadata_from_header(data) ?

	total_pixels := int(metadata.height * metadata.width)
	mut pixels := [][4]byte{ cap: total_pixels }
	mut array := [64][4]byte{}
	mut offset := 14

	mut last_pixel := [byte(0), 0, 0, 255]!

	for offset < data.len - 8 && pixels.len < total_pixels {
		current_byte := data[offset]
		mut new_pixel := [4]byte{}
		$if vqoi_debug ? {
			eprintln('decode: pos: $offset / $data.len, value: $current_byte')
		}
		if current_byte == 0b1111_1110 { // QOI_OP_RGB
			$if vqoi_debug ? {
				eprintln('decode: QOI_OP_RGB')
			}
			new_pixel[0] = data[offset + 1]
			new_pixel[1] = data[offset + 2]
			new_pixel[2] = data[offset + 3]
			new_pixel[3] = last_pixel[3]
			offset += 4
		} else if current_byte == 0b1111_1111 { // QOI_OP_RGBA
			$if vqoi_debug ? {
				eprintln('decode: QOI_OP_RGBA')
			}
			new_pixel[0] = data[offset + 1]
			new_pixel[1] = data[offset + 2]
			new_pixel[2] = data[offset + 3]
			new_pixel[3] = data[offset + 4]
			offset += 5
		} else if current_byte >> 6 == 0b00 { // QOI_OP_INDEX
			$if vqoi_debug ? {
				eprintln('decode: QOI_OP_INDEX')
			}
			new_pixel = array[current_byte]
			offset++
		} else if current_byte >> 6 == 0b01 { // QOI_OP_DIFF
			$if vqoi_debug ? {
				eprintln('decode: QOI_OP_DIFF')
			}
			new_pixel[0] = last_pixel[0] + (current_byte >> 4 & 0b0000_0011) - 2
			new_pixel[1] = last_pixel[1] + (current_byte >> 2 & 0b0000_0011) - 2
			new_pixel[2] = last_pixel[2] + (current_byte & 0b11) - 2
			new_pixel[3] = last_pixel[3]
			offset++
		} else if current_byte >> 6 == 0b10 { // QOI_OP_LUME
			$if vqoi_debug ? {
				eprintln('decode: QOI_OP_LUME')
			}
			next_byte := data[offset + 1]
			vg := (current_byte & 0x3f) - 32
			new_pixel[0] = last_pixel[0] + vg - 8 + (next_byte >> 4 & 0b0000_1111)
			new_pixel[1] = last_pixel[1] + vg
			new_pixel[2] = last_pixel[2] + vg - 8 + (next_byte & 0b0000_1111)
			new_pixel[3] = last_pixel[3]
			offset += 2
		} else if current_byte >> 6 == 0b11 { // QOI_OP_RUN
			$if vqoi_debug ? {
				eprintln('decode: QOI_OP_RUN len=${1 + current_byte & 0b0011_1111}')
			}
			for _ in 0 .. 1 + current_byte & 0b0011_1111 {
				$if vqoi_debug ? {
					eprintln('decode: => $last_pixel')
				}
				pixels << last_pixel
			}
			offset++
			continue
		}
		pixels << new_pixel
		$if vqoi_debug ? {
			eprintln('decode: => $new_pixel (${pixels.last()})')
		}
		array[color_hash(new_pixel)] = new_pixel
		last_pixel = new_pixel
	}
	return Image{pixels, metadata}
}
