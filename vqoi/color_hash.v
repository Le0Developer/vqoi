module vqoi

fn color_hash(rgba [4]byte) byte {
	return (rgba[0] * 3 + rgba[1] * 5 + rgba[2] * 7 + rgba[3] * 11) & 0x3f
}
