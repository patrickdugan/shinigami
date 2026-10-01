// secp256k1 arithmetic in pure Cairo.
//
// Nothing here uses a Starknet syscall, so signature checks built on this module can run in a
// standalone executable and be covered by a proof. Field and scalar arithmetic use the modular
// builtins through `core::circuit`. Group operations use the complete projective formulas of
// Renes, Costello and Batina ("Complete addition formulas for prime order elliptic curves",
// algorithms 7 and 9 for a = 0), which need no special cases for doubling, inverses or the
// point at infinity.

use core::circuit::{
    AddInputResultTrait, CircuitElement, CircuitInput, CircuitInputs, CircuitModulus,
    CircuitOutputsTrait, EvalCircuitTrait, circuit_add, circuit_inverse, circuit_mul, circuit_sub,
    u384,
};
use core::num::traits::Zero;

// The field prime p.
pub const FIELD_SIZE: u256 = 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f;
// The group order n.
pub const CURVE_ORDER: u256 = 0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141;
const GENERATOR_X: u256 = 0x79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798;
const GENERATOR_Y: u256 = 0x483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8;
// The curve is y^2 = x^3 + 7; the formulas use 3 * 7.
const CURVE_B: u256 = 7;
const CURVE_B3: u256 = 21;
const POW_127: u128 = 0x80000000000000000000000000000000;

// A point on the curve in affine coordinates. It is never the point at infinity.
#[derive(Copy, Drop, Debug, PartialEq)]
pub struct Point {
    pub x: u256,
    pub y: u256,
}

// A point in projective coordinates (X : Y : Z). The point at infinity is (0 : 1 : 0).
#[derive(Copy, Drop)]
struct ProjectivePoint {
    x: u384,
    y: u384,
    z: u384,
}

pub fn generator() -> Point {
    Point { x: GENERATOR_X, y: GENERATOR_Y }
}

fn modulus_of(value: u256) -> CircuitModulus {
    let value: u384 = value.into();
    [value.limb0, value.limb1, value.limb2, value.limb3].try_into().unwrap()
}

fn infinity() -> ProjectivePoint {
    ProjectivePoint { x: Zero::zero(), y: 1_u256.into(), z: Zero::zero() }
}

fn to_projective(point: Point) -> ProjectivePoint {
    ProjectivePoint { x: point.x.into(), y: point.y.into(), z: 1_u256.into() }
}

fn is_odd(value: u256) -> bool {
    value.low % 2 == 1
}

fn field_mul(a: u384, b: u384, modulus: CircuitModulus) -> u384 {
    let A = CircuitElement::<CircuitInput<0>> {};
    let B = CircuitElement::<CircuitInput<1>> {};
    let product = circuit_mul(A, B);
    let outputs = (product,).new_inputs().next(a).next(b).done().eval(modulus).unwrap();
    outputs.get_output(product)
}

// Returns (y^2, x^3 + 7).
fn curve_equation_sides(x: u384, y: u384, modulus: CircuitModulus) -> (u384, u384) {
    let X = CircuitElement::<CircuitInput<0>> {};
    let Y = CircuitElement::<CircuitInput<1>> {};
    let B = CircuitElement::<CircuitInput<2>> {};
    let lhs = circuit_mul(Y, Y);
    let rhs = circuit_add(circuit_mul(circuit_mul(X, X), X), B);
    let b: u384 = CURVE_B.into();
    let outputs = (lhs, rhs).new_inputs().next(x).next(y).next(b).done().eval(modulus).unwrap();
    (outputs.get_output(lhs), outputs.get_output(rhs))
}

// Complete point doubling.
fn projective_double(p: ProjectivePoint, modulus: CircuitModulus) -> ProjectivePoint {
    let X = CircuitElement::<CircuitInput<0>> {};
    let Y = CircuitElement::<CircuitInput<1>> {};
    let Z = CircuitElement::<CircuitInput<2>> {};
    let B3 = CircuitElement::<CircuitInput<3>> {};

    let t0 = circuit_mul(Y, Y);
    let z3 = circuit_add(t0, t0);
    let z3 = circuit_add(z3, z3);
    let z3 = circuit_add(z3, z3);
    let t1 = circuit_mul(Y, Z);
    let t2 = circuit_mul(Z, Z);
    let t2 = circuit_mul(B3, t2);
    let x3 = circuit_mul(t2, z3);
    let y3 = circuit_add(t0, t2);
    let z3 = circuit_mul(t1, z3);
    let t1 = circuit_add(t2, t2);
    let t2 = circuit_add(t1, t2);
    let t0 = circuit_sub(t0, t2);
    let y3 = circuit_mul(t0, y3);
    let y3 = circuit_add(x3, y3);
    let t1 = circuit_mul(X, Y);
    let x3 = circuit_mul(t0, t1);
    let x3 = circuit_add(x3, x3);

    let b3: u384 = CURVE_B3.into();
    let outputs = (x3, y3, z3)
        .new_inputs()
        .next(p.x)
        .next(p.y)
        .next(p.z)
        .next(b3)
        .done()
        .eval(modulus)
        .unwrap();
    ProjectivePoint {
        x: outputs.get_output(x3), y: outputs.get_output(y3), z: outputs.get_output(z3),
    }
}

// Complete point addition.
fn projective_add(
    p: ProjectivePoint, q: ProjectivePoint, modulus: CircuitModulus,
) -> ProjectivePoint {
    let X1 = CircuitElement::<CircuitInput<0>> {};
    let Y1 = CircuitElement::<CircuitInput<1>> {};
    let Z1 = CircuitElement::<CircuitInput<2>> {};
    let X2 = CircuitElement::<CircuitInput<3>> {};
    let Y2 = CircuitElement::<CircuitInput<4>> {};
    let Z2 = CircuitElement::<CircuitInput<5>> {};
    let B3 = CircuitElement::<CircuitInput<6>> {};

    let t0 = circuit_mul(X1, X2);
    let t1 = circuit_mul(Y1, Y2);
    let t2 = circuit_mul(Z1, Z2);
    let t3 = circuit_add(X1, Y1);
    let t4 = circuit_add(X2, Y2);
    let t3 = circuit_mul(t3, t4);
    let t4 = circuit_add(t0, t1);
    let t3 = circuit_sub(t3, t4);
    let t4 = circuit_add(Y1, Z1);
    let x3 = circuit_add(Y2, Z2);
    let t4 = circuit_mul(t4, x3);
    let x3 = circuit_add(t1, t2);
    let t4 = circuit_sub(t4, x3);
    let x3 = circuit_add(X1, Z1);
    let y3 = circuit_add(X2, Z2);
    let x3 = circuit_mul(x3, y3);
    let y3 = circuit_add(t0, t2);
    let y3 = circuit_sub(x3, y3);
    let x3 = circuit_add(t0, t0);
    let t0 = circuit_add(x3, t0);
    let t2 = circuit_mul(B3, t2);
    let z3 = circuit_add(t1, t2);
    let t1 = circuit_sub(t1, t2);
    let y3 = circuit_mul(B3, y3);
    let x3 = circuit_mul(t4, y3);
    let t2 = circuit_mul(t3, t1);
    let x3 = circuit_sub(t2, x3);
    let y3 = circuit_mul(y3, t0);
    let t1 = circuit_mul(t1, z3);
    let y3 = circuit_add(t1, y3);
    let t0 = circuit_mul(t0, t3);
    let z3 = circuit_mul(z3, t4);
    let z3 = circuit_add(z3, t0);

    let b3: u384 = CURVE_B3.into();
    let outputs = (x3, y3, z3)
        .new_inputs()
        .next(p.x)
        .next(p.y)
        .next(p.z)
        .next(q.x)
        .next(q.y)
        .next(q.z)
        .next(b3)
        .done()
        .eval(modulus)
        .unwrap();
    ProjectivePoint {
        x: outputs.get_output(x3), y: outputs.get_output(y3), z: outputs.get_output(z3),
    }
}

// Returns `None` for the point at infinity.
fn to_affine(p: ProjectivePoint, modulus: CircuitModulus) -> Option<Point> {
    if p.z.is_zero() {
        return Option::None;
    }
    let X = CircuitElement::<CircuitInput<0>> {};
    let Y = CircuitElement::<CircuitInput<1>> {};
    let Z = CircuitElement::<CircuitInput<2>> {};
    let z_inv = circuit_inverse(Z);
    let x = circuit_mul(X, z_inv);
    let y = circuit_mul(Y, z_inv);
    let outputs = (x, y).new_inputs().next(p.x).next(p.y).next(p.z).done().eval(modulus).unwrap();
    Option::Some(
        Point {
            x: outputs.get_output(x).try_into().unwrap(),
            y: outputs.get_output(y).try_into().unwrap(),
        },
    )
}

// Removes and returns the most significant bit of `word`, shifting the rest up.
fn pop_msb(ref word: u128) -> bool {
    let (bit, rest) = DivRem::div_rem(word, POW_127.try_into().unwrap());
    word = rest * 2;
    bit == 1
}

// Processes one 128-bit word of each scalar, most significant bit first.
fn ladder_word(
    mut acc: ProjectivePoint,
    mut a: u128,
    mut b: u128,
    p: ProjectivePoint,
    q: ProjectivePoint,
    p_plus_q: ProjectivePoint,
    modulus: CircuitModulus,
) -> ProjectivePoint {
    for _ in 0..128_u32 {
        acc = projective_double(acc, modulus);
        let bit_a = pop_msb(ref a);
        let bit_b = pop_msb(ref b);
        if bit_a && bit_b {
            acc = projective_add(acc, p_plus_q, modulus);
        } else if bit_a {
            acc = projective_add(acc, p, modulus);
        } else if bit_b {
            acc = projective_add(acc, q, modulus);
        }
    }
    acc
}

// Computes a * p + b * q with one shared double-and-add ladder.
fn double_scalar_mul(
    a: u256, p: Point, b: u256, q: Point, modulus: CircuitModulus,
) -> ProjectivePoint {
    let p = to_projective(p);
    let q = to_projective(q);
    let p_plus_q = projective_add(p, q, modulus);
    let acc = ladder_word(infinity(), a.high, b.high, p, q, p_plus_q, modulus);
    ladder_word(acc, a.low, b.low, p, q, p_plus_q, modulus)
}

// Computes a^(2^squarings) * b.
fn square_n_mul(a: u384, squarings: u32, b: u384, modulus: CircuitModulus) -> u384 {
    let mut result = a;
    for _ in 0..squarings {
        result = field_mul(result, result, modulus);
    }
    field_mul(result, b, modulus)
}

// Computes a^((p + 1) / 4), which is a square root of `a` whenever one exists. The exponent has
// blocks of 223, 22 and 2 one-bits; this is the addition chain used by libsecp256k1.
fn sqrt_candidate(a: u384, modulus: CircuitModulus) -> u384 {
    let x2 = square_n_mul(a, 1, a, modulus);
    let x3 = square_n_mul(x2, 1, a, modulus);
    let x6 = square_n_mul(x3, 3, x3, modulus);
    let x9 = square_n_mul(x6, 3, x3, modulus);
    let x11 = square_n_mul(x9, 2, x2, modulus);
    let x22 = square_n_mul(x11, 11, x11, modulus);
    let x44 = square_n_mul(x22, 22, x22, modulus);
    let x88 = square_n_mul(x44, 44, x44, modulus);
    let x176 = square_n_mul(x88, 88, x88, modulus);
    let x220 = square_n_mul(x176, 44, x44, modulus);
    let x223 = square_n_mul(x220, 3, x3, modulus);
    let t = square_n_mul(x223, 23, x22, modulus);
    let t = square_n_mul(t, 6, x2, modulus);
    let t = field_mul(t, t, modulus);
    field_mul(t, t, modulus)
}

// Whether (x, y) are the coordinates of a point on the curve.
pub fn is_on_curve(x: u256, y: u256) -> bool {
    if x >= FIELD_SIZE || y >= FIELD_SIZE {
        return false;
    }
    let (lhs, rhs) = curve_equation_sides(x.into(), y.into(), modulus_of(FIELD_SIZE));
    lhs == rhs
}

// Returns the point with the given x coordinate and y parity, or `None` if `x` is not the x
// coordinate of a point on the curve.
pub fn lift_x(x: u256, y_is_odd: bool) -> Option<Point> {
    if x >= FIELD_SIZE {
        return Option::None;
    }
    let modulus = modulus_of(FIELD_SIZE);
    let (_, rhs) = curve_equation_sides(x.into(), Zero::zero(), modulus);
    let y = sqrt_candidate(rhs, modulus);
    if field_mul(y, y, modulus) != rhs {
        return Option::None;
    }
    let y: u256 = y.try_into().unwrap();
    let y = if is_odd(y) == y_is_odd {
        y
    } else {
        FIELD_SIZE - y
    };
    Option::Some(Point { x, y })
}

// Reduces a 256-bit value modulo the group order.
pub fn reduce_scalar(value: u256) -> u256 {
    if value >= CURVE_ORDER {
        value - CURVE_ORDER
    } else {
        value
    }
}

// Returns a * p + b * q, or `None` if that is the point at infinity.
pub fn linear_combination(a: u256, p: Point, b: u256, q: Point) -> Option<Point> {
    let modulus = modulus_of(FIELD_SIZE);
    to_affine(double_scalar_mul(a, p, b, q, modulus), modulus)
}

// Returns point + tweak * G, or `None` if the tweak is not below the group order or the result
// is the point at infinity.
pub fn tweak_add(point: Point, tweak: u256) -> Option<Point> {
    if tweak >= CURVE_ORDER {
        return Option::None;
    }
    linear_combination(1, point, tweak, generator())
}

// Checks the BIP340 verification equation for a challenge `e` that the caller has already
// computed: R = s * G - e * P must be a finite point with even y and x coordinate r.
pub fn verify_schnorr_equation(r: u256, s: u256, e: u256, public_key: Point) -> bool {
    if r >= FIELD_SIZE || s >= CURVE_ORDER {
        return false;
    }
    let e = reduce_scalar(e);
    let minus_e = if e == 0 {
        0
    } else {
        CURVE_ORDER - e
    };
    match linear_combination(s, generator(), minus_e, public_key) {
        Option::Some(point) => !is_odd(point.y) && point.x == r,
        Option::None => false,
    }
}

// Verifies an ECDSA signature as Bitcoin consensus does: any r and s in [1, n) are accepted,
// including a high s, which is only a relay policy matter.
pub fn verify_ecdsa(msg_hash: u256, r: u256, s: u256, public_key: Point) -> bool {
    if r == 0 || r >= CURVE_ORDER || s == 0 || s >= CURVE_ORDER {
        return false;
    }

    let Z = CircuitElement::<CircuitInput<0>> {};
    let R = CircuitElement::<CircuitInput<1>> {};
    let S = CircuitElement::<CircuitInput<2>> {};
    let s_inv = circuit_inverse(S);
    let u1 = circuit_mul(Z, s_inv);
    let u2 = circuit_mul(R, s_inv);
    let z: u384 = reduce_scalar(msg_hash).into();
    let r_in: u384 = r.into();
    let s_in: u384 = s.into();
    let outputs = (u1, u2)
        .new_inputs()
        .next(z)
        .next(r_in)
        .next(s_in)
        .done()
        .eval(modulus_of(CURVE_ORDER))
        .unwrap();
    let u1: u256 = outputs.get_output(u1).try_into().unwrap();
    let u2: u256 = outputs.get_output(u2).try_into().unwrap();

    match linear_combination(u1, generator(), u2, public_key) {
        Option::Some(point) => reduce_scalar(point.x) == r,
        Option::None => false,
    }
}
