module vqoi

struct EncoderState {
mut:
	run byte
	array [64][4]byte
	last_pixel [4]byte
}

pub fn (mut state EncoderState) encode_pixel(pixel [4]byte) []byte {
	mut result := []byte{}
	// repeating pixel [QOI_OP_RUN]
	if pixel == state.last_pixel {
		state.run++
		// 62 and 63 are reserved for QOI_OP_RGB and QOI_OP_RGBA
		if state.run > 61 {
			$if vqoi_debug ? {
				eprintln('encode: QOI_OP_RUN, len=$state.run (premature restart)')
			}
			// result << (0b11_000000 | (state.run - 1))
			result << 0b11_111101  // 61-byte run length
			state.run = 0
		}
		return result
	} else if state.run > 0 {
		$if vqoi_debug ? {
			eprintln('encode: QOI_OP_RUN, len=$state.run')
		}
		result << (0b11_000000 | (state.run - 1))
		state.run = 0
	}

	pixel_hash := color_hash(pixel)
	if state.array[pixel_hash] == pixel { // backreference [QOI_OP_INDEX]
		$if vqoi_debug ? {
			eprintln('encode: QOI_OP_INDEX, index: ${pixel_hash}')
		}
		result << pixel_hash
	} else if pixel[3] != state.last_pixel[3] { // alpha channel changed [QOI_OP_RGBA]
		$if vqoi_debug ? {
			eprintln('encode: QOI_OP_RGBA, new: ${pixel[3]}, old: ${state.last_pixel[3]}')
		}
		result << 0b11_111111
		// sadly we can't do `result << pixel`
		result << pixel[0]
		result << pixel[1]
		result << pixel[2]
		result << pixel[3]
	} else {
		vr := i8(pixel[0]) - i8(state.last_pixel[0])
		vg := i8(pixel[1]) - i8(state.last_pixel[1])
		vb := i8(pixel[2]) - i8(state.last_pixel[2])

		vg_r := vr - vg
		vg_b := vb - vg

		if vr > -3 && vr < 2 && vg > -3 && vg < 2 && vb > -3 && vb < 2 { // small difference [QOI_OP_DIFF]
			$if vqoi_debug ? {
				eprintln('encode: QOI_OP_DIFF, vr: $vr, vg: $vg, vb: $vb')
			}
			result << (0b01_000000 | byte(vr + 2) << 4 | byte(vg + 2) << 2 | byte(vb + 2))
		} else if vg_r > -9 && vg_r < 8 && vg > -33 && vg < 32 && vg_b > -9 && vg_b < 8 { // [QOI_LUME]
			$if vqoi_debug ? {
				eprintln('encode: QOI_OP_LUME, vg: $vg, vg_r: $vg_r, vg_b: $vg_b')
			}
			result << (0b10_000000 | byte(vg + 32))
			result << (byte(vg_r + 8) << 4 | byte(vg_b + 8))
		} else { // fallback to new pixel [QOI_OP_RGB]
			$if vqoi_debug ? {
				eprintln('encode: QOI_OP_RGB')
			}
			result << 0b11_111110
			result << pixel[0]
			result << pixel[1]
			result << pixel[2]
		}
	}

	pixel_clone := [pixel[0], pixel[1], pixel[2], pixel[3]]!
	state.last_pixel = pixel_clone
	state.array[pixel_hash] = pixel_clone

	return result
}

pub fn (mut state EncoderState) encode_footer() []byte {
	mut result := []byte{}
	if state.run > 0 {
		$if vqoi_debug ? {
			eprintln('encode: QOI_OP_RUN, len=$state.run (exit)')
		}
		result << 0b11_000000 | (state.run - 1)
	}
	result << magic_footer
	return result
}

pub fn new_encoder() EncoderState {
	default_last_pixel := [byte(0), 0, 0, 255]!
	return EncoderState{last_pixel: default_last_pixel}
}

pub fn encode(image Image) []byte {
	mut result := []byte{}
	result << image.metadata.as_header()
	mut state := new_encoder()
	for pixel in image.pixels {
		result << state.encode_pixel(pixel)
	}
	result << state.encode_footer()
	return result
}
