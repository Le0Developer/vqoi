module vqoi

pub type Pixel = [4]byte


pub const header_size = 16


// "qoif"
pub const magic_header = [byte(113), 111, 105, 102]

// 7 * \0 + \1
pub const magic_footer = [byte(0), 0, 0, 0, 0, 0, 0, 1]
