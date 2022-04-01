module vqoi


pub fn encode(image Image) []byte {
	mut result := []byte{}
	result << image.metadata.as_header()

	mut array := [64][4]byte{}
	mut last_pixel := [byte(0), 0, 0, 255]!

	mut run := byte(0)
	for pixel in image.rgba {
		$if vqoi_debug ? {
			eprintln('encode: pos: $result.len, pixel: $pixel')
		}
		// QOI_OP_RUN
		if pixel == last_pixel {
			run++
			// 62 and 63 are reserved for QOI_OP_RGB and QOI_OP_RGBA
			if run > 61 {
				$if vqoi_debug ? {
					eprintln('encode: QOI_OP_RUN, len=$run (premature restart)')
				}
				result << (0b11 << 6 | (run - 1))
				run = 0
			}
			continue
		} else if run > 0 {
			$if vqoi_debug ? {
				eprintln('encode: QOI_OP_RUN, len=$run ')
			}
			result << (0b11 << 6 | (run - 1))
			run = 0
		}

		if array[color_hash(pixel)] == pixel { // QOI_OP_INDEX
			$if vqoi_debug ? {
				eprintln('encode: QOI_OP_INDEX, index: ${color_hash(pixel)}')
			}
			result << color_hash(pixel)
		} else if last_pixel[3] != pixel[3] { // QOI_OP_RGBA
			$if vqoi_debug ? {
				eprintln('encode: QOI_OP_RGBA, new: ${pixel[3]}, old: ${last_pixel[3]}')
			}
			result << 0b1111_1111
			result << pixel[0]
			result << pixel[1]
			result << pixel[2]
			result << pixel[3]
		} else {
			vr := i8(pixel[0]) - i8(last_pixel[0])
			vg := i8(pixel[1]) - i8(last_pixel[1])
			vb := i8(pixel[2]) - i8(last_pixel[2])

			vg_r := vr - vg
			vg_b := vb - vg

			if vr > -3 && vr < 2 && vg > -3 && vg < 2 && vb > -3 && vb < 2 { // QOI_OP_DIFF
				$if vqoi_debug ? {
					eprintln('encode: QOI_OP_DIFF, vr: $vr, vg: $vg, vb: $vb')
				}
				result << (0b01 << 6 | byte(vr + 2) << 4 | byte(vg + 2) << 2 | byte(vb + 2))
			} else if vg_r > -9 && vg_r < 8 && vg > -33 && vg < 32 && vg_b > -9 && vg_b < 8 { // QOI_LUME
				$if vqoi_debug ? {
					eprintln('encode: QOI_OP_LUME, vg: $vg, vg_r: $vg_r, vg_b: $vg_b')
				}
				result << (0b10 << 6 | byte(vg + 32))
				result << (byte(vg_r + 8) << 4 | byte(vg_b + 8))
			} else { // QOI_OP_RGB
				$if vqoi_debug ? {
					eprintln('encode: QOI_OP_RGB')
				}
				result << 0b1111_1110
				result << pixel[0]
				result << pixel[1]
				result << pixel[2]
			}
		}
		last_pixel = pixel
		array[color_hash(pixel)] = pixel
	}

	if run > 0 {
		$if vqoi_debug ? {
			eprintln('encode: QOI_OP_RUN, len=$run (exit)')
		}
		result << 0b11 << 6 | (run - 1)
	}
	result << [byte(0), 0, 0, 0, 0, 0, 0, 1] // magic ending
	return result
}
