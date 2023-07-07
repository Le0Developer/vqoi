// tested with https://qoiformat.org/qoi_test_images.zip

module main

import os
import vqoi

fn main() {
	for arg in os.args[1..] {
		try_file(arg) or {
			println('[FAILED ] $arg: $err')
			continue
		}
		println('[SUCCESS] $arg')
	}
}

fn try_file(filename string) ? {
	data := (os.read_file(filename) ?).bytes()
	image := vqoi.decode(data) ?
	encoded := vqoi.encode(image)
	if data != encoded {
		return error('does not match')
	}
}
