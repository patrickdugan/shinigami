use crate::errors::Error;
use crate::transaction::{
    EngineTransactionTrait, EngineTransactionInputTrait, EngineTransactionOutputTrait,
};
use crate::signature::{schnorr, taproot_signature::{TaprootSigVerifierImpl}};
use crate::engine::Engine;
use crate::hash_tag::{HashTag, tagged_hash};
use crate::secp256k1;
use crate::secp256k1::Point;
use shinigami_utils::byte_array::{U256IntoByteArray, u256_from_byte_array_with_offset};
use shinigami_utils::bytecode::write_var_int;

#[derive(Destruct)]
pub struct TaprootContext {
    pub annex: @ByteArray,
    pub code_sep: u32,
    pub tapleaf_hash: u256,
    sig_ops_budget: i32,
    pub must_succeed: bool,
}

#[derive(Drop)]
pub struct ControlBlock {
    internal_pubkey: Point,
    output_key_y_is_odd: bool,
    pub leaf_version: u8,
    control_block: @ByteArray,
}

// Computes the BIP-341 leaf hash:
// tagged_hash("TapLeaf", leaf_version || compact_size(script) || script).
pub fn tap_hash(script: @ByteArray, version: u8) -> u256 {
    let mut msg: ByteArray = "";
    msg.append_byte(version);
    write_var_int(ref msg, script.len().into());
    msg.append(script);
    tagged_hash(HashTag::TapLeaf, @msg)
}

// Combines two nodes of the script tree. BIP-341 orders the two 32-byte hashes
// lexicographically, which for big-endian values is numeric order.
pub fn tap_branch_hash(a: u256, b: u256) -> u256 {
    let (first, second) = if a < b {
        (a, b)
    } else {
        (b, a)
    };
    let mut msg: ByteArray = first.into();
    msg.append(@second.into());
    tagged_hash(HashTag::TapBranch, @msg)
}

// Computes the taproot output key Q = P + tagged_hash("TapTweak", P || merkle_root) * G.
// Returns `None` where BIP-341 fails: the tweak is not below the curve order, or Q is the point
// at infinity.
pub fn compute_taproot_output_key(internal_pubkey: Point, merkle_root: u256) -> Option<Point> {
    let mut msg: ByteArray = internal_pubkey.x.into();
    msg.append(@merkle_root.into());
    let tweak = tagged_hash(HashTag::TapTweak, @msg);
    secp256k1::tweak_add(internal_pubkey, tweak)
}

#[generate_trait()]
pub impl ControlBlockImpl of ControlBlockTrait {
    // TODO: From parse
    fn new(
        internal_pubkey: Point, output_key_y_is_odd: bool, leaf_version: u8, control_block: @ByteArray,
    ) -> ControlBlock {
        ControlBlock {
            internal_pubkey: internal_pubkey,
            output_key_y_is_odd: output_key_y_is_odd,
            leaf_version: leaf_version,
            control_block: control_block,
        }
    }

    // Computes the Merkle root that this control block commits to for `script`: the leaf hash
    // folded with each 32-byte node of the control block's path.
    fn root_hash(self: @ControlBlock, script: @ByteArray) -> u256 {
        let control_block = *self.control_block;
        let control_block_len = control_block.len();
        let mut node = tap_hash(script, *self.leaf_version);
        let mut offset = CONTROL_BLOCK_BASE_SIZE;
        while offset != control_block_len {
            let sibling = u256_from_byte_array_with_offset(
                control_block, offset, CONTROL_BLOCK_NODE_SIZE,
            );
            node = tap_branch_hash(node, sibling);
            offset += CONTROL_BLOCK_NODE_SIZE;
        };
        node
    }

    // Checks that the witness program is the output key committing to `script` through this
    // control block, and that the control block states the right parity for that key.
    fn verify_taproot_leaf(
        self: @ControlBlock, witness_program: @ByteArray, script: @ByteArray,
    ) -> Result<(), felt252> {
        let root_hash = self.root_hash(script);
        let output_key = match compute_taproot_output_key(*self.internal_pubkey, root_hash) {
            Option::Some(key) => key,
            Option::None => { return Result::Err(Error::TAPROOT_INVALID_MERKLE_PROOF); },
        };
        let expected_witness_program: ByteArray = output_key.x.into();
        if witness_program != @expected_witness_program {
            return Result::Err(Error::TAPROOT_INVALID_MERKLE_PROOF);
        }

        let y_is_odd = output_key.y.low % 2 == 1;
        if *self.output_key_y_is_odd != y_is_odd {
            return Result::Err(Error::TAPROOT_PARITY_MISMATCH);
        }

        return Result::Ok(());
    }
}

const CONTROL_BLOCK_BASE_SIZE: u32 = 33;
const CONTROL_BLOCK_NODE_SIZE: u32 = 32;
const CONTROL_BLOCK_MAX_NODE_COUNT: u32 = 128;
const CONTROL_BLOCK_MAX_SIZE: u32 = CONTROL_BLOCK_BASE_SIZE
    + (CONTROL_BLOCK_MAX_NODE_COUNT * CONTROL_BLOCK_NODE_SIZE);

const SIG_OPS_DELTA: i32 = 50;
const BASE_CODE_SEP: u32 = 0xFFFFFFFF;
const TAPROOT_ANNEX_TAG: u8 = 0x50;
const TAPROOT_LEAF_MASK: u8 = 0xFE;
pub const BASE_LEAF_VERSION: u8 = 0xc0;

#[generate_trait()]
pub impl TaprootContextImpl of TaprootContextTrait {
    fn new(witness_size: i32) -> TaprootContext {
        TaprootContext {
            annex: @"",
            code_sep: BASE_CODE_SEP,
            tapleaf_hash: 0,
            sig_ops_budget: SIG_OPS_DELTA + witness_size,
            must_succeed: false,
        }
    }

    fn empty() -> TaprootContext {
        TaprootContext {
            annex: @"",
            code_sep: BASE_CODE_SEP,
            tapleaf_hash: 0,
            sig_ops_budget: SIG_OPS_DELTA,
            must_succeed: false,
        }
    }

    fn verify_taproot_spend<
        T,
        I,
        O,
        impl IEngineTransactionInputTrait: EngineTransactionInputTrait<I>,
        impl IEngineTransactionOutputTrait: EngineTransactionOutputTrait<O>,
        impl IEngineTransactionTrait: EngineTransactionTrait<
            T, I, O, IEngineTransactionInputTrait, IEngineTransactionOutputTrait,
        >,
        +Drop<T>,
        +Drop<I>,
        +Drop<O>,
        +Default<T>,
    >(
        ref engine: Engine<T>,
        witness_program: @ByteArray,
        raw_sig: @ByteArray,
        tx: @T,
        tx_idx: u32,
    ) -> Result<(), felt252> {
        let witness: Span<ByteArray> = tx.get_transaction_inputs()[tx_idx].get_witness();
        let mut annex = @"";
        if is_annexed_witness(witness, witness.len()) {
            annex = witness[witness.len() - 1];
        }

        let mut verifier = TaprootSigVerifierImpl::<
            T,
        >::new(raw_sig, witness_program, annex, ref engine)?; // mut ?
        let is_valid = TaprootSigVerifierImpl::<T>::verify(verifier);
        if is_valid.is_err() {
            return Result::Err(Error::TAPROOT_INVALID_SIG);
        }
        // if verify.sigvalid Ok() else error invalid sig
        Result::Ok(())
    }

    fn use_ops_budget(ref self: TaprootContext) -> Result<(), felt252> {
        self.sig_ops_budget -= SIG_OPS_DELTA;

        if self.sig_ops_budget < 0 {
            return Result::Err(Error::TAPROOT_SIGOPS_EXCEEDED);
        }
        return Result::Ok(());
    }
}

pub fn parse_control_block(control_block: @ByteArray) -> Result<ControlBlock, felt252> {
    let control_block_len = control_block.len();
    if control_block_len < CONTROL_BLOCK_BASE_SIZE || control_block_len > CONTROL_BLOCK_MAX_SIZE {
        return Result::Err(Error::TAPROOT_INVALID_CONTROL_BLOCK);
    }
    if (control_block_len - CONTROL_BLOCK_BASE_SIZE) % CONTROL_BLOCK_NODE_SIZE != 0 {
        return Result::Err(Error::TAPROOT_INVALID_CONTROL_BLOCK);
    }

    let leaf_version = control_block[0] & TAPROOT_LEAF_MASK;
    let output_key_y_is_odd = (control_block[0] & 0x01) == 0x01;

    let mut raw_pubkey = "";
    let pubkey_end = 33;
    let mut i = 1;
    while i != pubkey_end {
        raw_pubkey.append_byte(control_block[i]);
        i += 1;
    };
    let pubkey = schnorr::parse_schnorr_pub_key(@raw_pubkey)?;
    return Result::Ok(
        ControlBlock {
            internal_pubkey: pubkey,
            output_key_y_is_odd: output_key_y_is_odd,
            leaf_version: leaf_version,
            control_block: control_block,
        },
    );
}

pub fn is_annexed_witness(witness: Span<ByteArray>, witness_len: usize) -> bool {
    if witness_len < 2 {
        return false;
    }

    let last_elem = witness[witness_len - 1];
    return last_elem.len() > 0 && last_elem[0] == TAPROOT_ANNEX_TAG;
}
