#[feature("deprecated-sha256")]
use alexandria_math::sha256::sha256;

// Alexandria's pure-Cairo SHA-256 is used instead of the core syscall so this
// module can execute inside a Cairo executable and be proved by STWO. The
// dependency is pinned to an immutable GitHub commit in the workspace manifest.
pub fn compute_sha256_byte_array(byte: @ByteArray) -> [u32; 8] {
    let mut input: Array<u8> = array![];
    let mut index = 0;
    while index < byte.len() {
        input.append(byte[index]);
        index += 1;
    }

    let digest = sha256(input);
    assert(digest.len() == 32, 'sha256 digest length');
    let digest = digest.span();
    [
        word_at(digest, 0), word_at(digest, 4), word_at(digest, 8), word_at(digest, 12),
        word_at(digest, 16), word_at(digest, 20), word_at(digest, 24), word_at(digest, 28),
    ]
}

fn word_at(digest: Span<u8>, offset: usize) -> u32 {
    (*digest[offset]).into() * 0x1000000
        + (*digest[offset + 1]).into() * 0x10000
        + (*digest[offset + 2]).into() * 0x100
        + (*digest[offset + 3]).into()
}

pub fn sha256_byte_array(byte: @ByteArray) -> ByteArray {
    let msg_hash = compute_sha256_byte_array(byte);
    let mut hash_value: ByteArray = "";
    for word in msg_hash.span() {
        hash_value.append_word((*word).into(), 4);
    }

    hash_value
}

pub fn sha256_u256(hash: [u32; 8]) -> u256 {
    let mut bytes = "";
    for word in hash.span() {
        bytes.append_word((*word).into(), 4);
    }

    let msg_hash = compute_sha256_byte_array(@bytes);
    let mut hash_value: u256 = 0;
    for word in msg_hash.span() {
        hash_value *= 0x100000000;
        hash_value = hash_value + (*word).into();
    }

    hash_value
}

pub fn double_sha256_bytearray(byte: @ByteArray) -> ByteArray {
    return sha256_byte_array(@sha256_byte_array(byte));
}

pub fn simple_sha256(byte: @ByteArray) -> u256 {
    let msg_hash = compute_sha256_byte_array(byte);
    let mut hash_value: u256 = 0;
    for word in msg_hash.span() {
        hash_value *= 0x100000000;
        hash_value = hash_value + (*word).into();
    }

    hash_value
}

pub fn double_sha256(byte: @ByteArray) -> u256 {
    let msg_hash = compute_sha256_byte_array(byte);
    let mut res_bytes = "";
    for word in msg_hash.span() {
        res_bytes.append_word((*word).into(), 4);
    }
    let msg_hash = compute_sha256_byte_array(@res_bytes);
    let mut hash_value: u256 = 0;
    for word in msg_hash.span() {
        hash_value *= 0x100000000;
        hash_value = hash_value + (*word).into();
    }

    hash_value
}

pub fn hash_to_u256(hash: [u32; 8]) -> u256 {
    let mut hash_value: u256 = 0;
    for word in hash.span() {
        hash_value *= 0x100000000;
        hash_value = hash_value + (*word).into();
    }

    hash_value
}

#[cfg(test)]
mod tests {
    use core::sha256::compute_sha256_byte_array as core_sha256;
    use super::compute_sha256_byte_array;

    #[test]
    fn software_sha256_matches_empty_vector() {
        assert(
            compute_sha256_byte_array(
                @"",
            ) == [
                0xe3b0c442, 0x98fc1c14, 0x9afbf4c8, 0x996fb924, 0x27ae41e4, 0x649b934c, 0xa495991b,
                0x7852b855,
            ],
            'empty sha256 mismatch',
        );
    }

    #[test]
    fn software_sha256_matches_abc_vector() {
        assert(
            compute_sha256_byte_array(
                @"abc",
            ) == [
                0xba7816bf, 0x8f01cfea, 0x414140de, 0x5dae2223, 0xb00361a3, 0x96177a9c, 0xb410ff61,
                0xf20015ad,
            ],
            'abc sha256 mismatch',
        );
    }

    #[test]
    fn software_sha256_matches_core_across_padding_boundaries() {
        let lengths: Array<usize> = array![
            0, 1, 2, 3, 31, 32, 33, 54, 55, 56, 57, 63, 64, 65, 119, 120, 121, 127, 128, 129, 255,
            256,
        ];
        let mut length_index: usize = 0;
        while length_index < lengths.len() {
            let length = *lengths.at(length_index);
            let mut input: ByteArray = "";
            let mut index: usize = 0;
            while index < length {
                let byte: u8 = ((index * 17 + length * 29) % 256).try_into().unwrap();
                input.append_byte(byte);
                index += 1;
            }
            assert(
                compute_sha256_byte_array(@input) == core_sha256(@input), 'software sha mismatch',
            );
            length_index += 1;
        };
    }
}
