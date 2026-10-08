// Runs one script verification case from Bitcoin Core's test vectors.
//
// The case gives a fully built spending transaction, the outputs spent by each of its inputs,
// the input to verify and the script verification flags. `scripts/core_vectors/` turns
// Bitcoin Core's `script_tests.json` and `script_assets_test.json` into such cases and compares
// the outcome with Bitcoin Core's expectation.

use shinigami_engine::engine::EngineImpl;
use shinigami_engine::hash_cache::HashCacheImpl;
use shinigami_engine::transaction::{EngineInternalTransactionTrait, UTXO};

// Returned when the input is valid; any other value is the engine's error.
pub const VALID: felt252 = 'VALID';

#[derive(Drop, Serde)]
pub struct Prevout {
    pub amount: i64,
    pub script_pubkey: ByteArray,
}

#[derive(Drop, Serde)]
pub struct Case {
    // The spending transaction, consensus-serialized with its witness.
    pub transaction: ByteArray,
    // The outputs spent by the transaction's inputs, in input order.
    pub prevouts: Array<Prevout>,
    pub index: u32,
    pub flags: u32,
}

#[executable]
fn run_case(case: Case) -> felt252 {
    verify(case)
}

// Runs several cases in one execution. A panic in any of them aborts the whole batch.
#[executable]
fn run_cases(cases: Array<Case>) -> Array<felt252> {
    let mut results = array![];
    for case in cases {
        results.append(verify(case));
    };
    results
}

pub fn verify(case: Case) -> felt252 {
    let Case { transaction, prevouts, index, flags } = case;
    let mut utxos: Array<UTXO> = array![];
    for prevout in prevouts.span() {
        utxos
            .append(
                UTXO {
                    amount: *prevout.amount,
                    pubkey_script: prevout.script_pubkey.clone(),
                    block_height: 0,
                },
            );
    };
    let transaction = EngineInternalTransactionTrait::deserialize(transaction, 0, utxos);
    let prevout = prevouts.at(index);
    let hash_cache = HashCacheImpl::new(@transaction);
    let mut engine = match EngineImpl::new(
        prevout.script_pubkey, @transaction, index, flags, *prevout.amount, @hash_cache,
    ) {
        Result::Ok(engine) => engine,
        Result::Err(e) => { return e; },
    };
    match engine.execute() {
        Result::Ok(_) => VALID,
        Result::Err(e) => e,
    }
}
