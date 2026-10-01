use crate::secp256k1::{
    CURVE_ORDER, FIELD_SIZE, Point, generator, is_on_curve, lift_x, linear_combination, tweak_add,
    verify_ecdsa,
};
use starknet::SyscallResultTrait;
use starknet::secp256_trait::{Secp256PointTrait, Secp256Trait, is_valid_signature};
use starknet::secp256k1::Secp256k1Point;

fn two_g() -> Point {
    Point {
        x: 0xc6047f9441ed7d6d3045406e95c07cd85c778e4b8cef3ca7abac09b95c709ee5,
        y: 0x1ae168fea63dc339a3c58419466ceaeef7f632653266d0e1236431a950cfe52a,
    }
}

fn three_g() -> Point {
    Point {
        x: 0xf9308a019258c31049344f85f89d5229b531c845836f99b08601f113bce036f9,
        y: 0x388f7b0f632de8140fe337e62a37f3566500a99934c2231b6cb9fd7584b8e672,
    }
}

fn negate(point: Point) -> Point {
    Point { x: point.x, y: FIELD_SIZE - point.y }
}

fn syscall_point(point: Point) -> Secp256k1Point {
    Secp256Trait::<Secp256k1Point>::secp256_ec_new_syscall(point.x, point.y)
        .unwrap_syscall()
        .unwrap()
}

// a * p + b * q computed by the Starknet secp256k1 syscalls. Both scalars must be non-zero and
// the result finite.
fn syscall_linear_combination(a: u256, p: Point, b: u256, q: Point) -> Point {
    let ap = syscall_point(p).mul(a).unwrap_syscall();
    let bq = syscall_point(q).mul(b).unwrap_syscall();
    let (x, y) = ap.add(bq).unwrap_syscall().get_coordinates().unwrap_syscall();
    Point { x, y }
}

#[test]
fn test_generator_is_on_curve() {
    let g = generator();
    assert!(is_on_curve(g.x, g.y));
    assert!(!is_on_curve(g.x, g.y + 1));
    assert!(!is_on_curve(FIELD_SIZE, g.y));
}

#[test]
fn test_small_multiples() {
    let g = generator();
    // Adding a point to itself goes through the addition formula, not the doubling one.
    assert_eq!(tweak_add(g, 1).unwrap(), two_g());
    assert_eq!(tweak_add(g, 2).unwrap(), three_g());
    assert_eq!(tweak_add(two_g(), 1).unwrap(), three_g());
    assert_eq!(linear_combination(2, g, 0, g).unwrap(), two_g());
    assert_eq!(linear_combination(0, g, 3, g).unwrap(), three_g());
    assert_eq!(linear_combination(1, g, 1, two_g()).unwrap(), three_g());
}

#[test]
fn test_infinity() {
    let g = generator();
    assert!(linear_combination(0, g, 0, g).is_none());
    assert!(linear_combination(1, g, 1, negate(g)).is_none());
    assert!(linear_combination(CURVE_ORDER, g, 0, g).is_none());
    assert!(tweak_add(negate(g), 1).is_none());
    assert!(tweak_add(g, CURVE_ORDER - 1).is_none());
    assert_eq!(linear_combination(CURVE_ORDER - 1, g, 0, g).unwrap(), negate(g));
}

#[test]
fn test_tweak_add_rejects_out_of_range_tweak() {
    assert!(tweak_add(generator(), CURVE_ORDER).is_none());
    assert!(tweak_add(generator(), CURVE_ORDER + 1).is_none());
}

#[test]
fn test_lift_x() {
    let g = generator();
    assert_eq!(lift_x(g.x, false).unwrap(), g);
    assert_eq!(lift_x(g.x, true).unwrap(), negate(g));
    assert_eq!(lift_x(three_g().x, false).unwrap(), three_g());
    // BIP340 test vector 5: not the x coordinate of a curve point.
    assert!(
        lift_x(0xeefdea4cdb677750a420fee807eacf21eb9898ae79b9768766e4faa04a2d4a34, false).is_none(),
    );
    assert!(lift_x(FIELD_SIZE, false).is_none());
}

#[test]
fn test_lift_x_matches_syscall() {
    let xs: Array<u256> = array![
        0xdff1d77f2a671c5f36183726db2341be58feae1da2deced843240f7b502ba659,
        0xdd308afec5777e13121fa72b9cc1b7cc0139715309b086c960e18fd969774eb8,
        0x25d1dff95105f5253c4022f628a996ad3a0d95fbf21d468a1b33f8c160d8f517,
        0xd69c3509bb99e412e68b0fe8544e72837dfa30746d8be2aa65975f29d22dc7b9,
    ];
    for x in xs {
        for parity in array![false, true] {
            let expected = Secp256Trait::<Secp256k1Point>::secp256_ec_get_point_from_x_syscall(
                x, parity,
            )
                .unwrap_syscall()
                .unwrap();
            let (expected_x, expected_y) = expected.get_coordinates().unwrap_syscall();
            assert_eq!(lift_x(x, parity).unwrap(), Point { x: expected_x, y: expected_y });
        }
    }
}

#[test]
fn test_linear_combination_matches_syscall() {
    let scalars: Array<u256> = array![
        1,
        2,
        0xffffffffffffffffffffffffffffffff,
        0x100000000000000000000000000000000,
        0x8000000000000000000000000000000000000000000000000000000000000000,
        0xb7e151628aed2a6abf7158809cf4f3c762e7160f38b4da56a784d9045190cfef,
        0x243f6a8885a308d313198a2e03707344a4093822299f31d0082efa98ec4e6c89,
        CURVE_ORDER - 2,
    ];
    let p = three_g();
    let q = lift_x(0xdff1d77f2a671c5f36183726db2341be58feae1da2deced843240f7b502ba659, true)
        .unwrap();
    let scalars = scalars.span();
    for i in 0..scalars.len() {
        let a = *scalars[i];
        let b = *scalars[(i + 3) % scalars.len()];
        assert_eq!(linear_combination(a, p, b, q).unwrap(), syscall_linear_combination(a, p, b, q));
        assert_eq!(
            linear_combination(b, generator(), a, q).unwrap(),
            syscall_linear_combination(b, generator(), a, q),
        );
    }
}

#[test]
fn test_verify_ecdsa_matches_corelib() {
    // Input 0 of the block 496 transaction (low s).
    let public_key = Point {
        x: 0x4ca7baf6d8b658abd04223909d82f1764740bdc9317255f54e4910f888bd8295,
        y: 0x0e33236798517591e4c2181f69b5eaa2fa1f21866780a0cc5d8396a04fd36310,
    };
    let msg_hash = 0x213d145831c9c976f99d0383404431f7556e7329dfa34e79354863ffc7084f53;
    let r = 0xcb2c6b346a978ab8c61b18b5e9397755cbd17d6eb2fe0083ef32e067fa6c785a;
    let s = 0x6ce44e613f31d9a6b0517e46f3db1576e9812cc98d159bfdaf759a5014081b5c;
    assert!(is_on_curve(public_key.x, public_key.y));
    assert!(is_valid_signature(msg_hash, r, s, syscall_point(public_key)));
    assert!(verify_ecdsa(msg_hash, r, s, public_key));
    assert!(!verify_ecdsa(msg_hash + 1, r, s, public_key));
    assert!(!verify_ecdsa(msg_hash, r, s + 1, public_key));
    assert!(!verify_ecdsa(msg_hash, r, s, generator()));
}

#[test]
fn test_verify_ecdsa_accepts_high_s() {
    // Input 1 of the block 496 transaction. Its s is above n / 2, which consensus accepts.
    let public_key = Point {
        x: 0xfe1b9ccf732e1f6b760c5ed3152388eeeadd4a073e621f741eb157e6a62e3547,
        y: 0xc8e939abbd6a513bf3a1fbe28f9ea85a4e64c526702435d726f7ff14da40bae4,
    };
    let msg_hash = 0x90ac67b0e9cd3fe953896dd371ff971e573a7774d1e5efc10c629a413d1cf92e;
    let r = 0x47957cdd957cfd0becd642f6b84d82f49b6cb4c51a91f49246908af7c3cfdf4a;
    let s = 0xe96b46621f1bffcf5ea5982f88cef651e9354f5791602369bf5a82a6cd61a625;
    assert!(s > CURVE_ORDER / 2);
    assert!(verify_ecdsa(msg_hash, r, s, public_key));
    assert!(verify_ecdsa(msg_hash, r, CURVE_ORDER - s, public_key));
}

#[test]
fn test_verify_ecdsa_rejects_out_of_range() {
    let g = generator();
    assert!(!verify_ecdsa(1, 0, 1, g));
    assert!(!verify_ecdsa(1, 1, 0, g));
    assert!(!verify_ecdsa(1, CURVE_ORDER, 1, g));
    assert!(!verify_ecdsa(1, 1, CURVE_ORDER, g));
}
