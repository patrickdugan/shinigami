// Generated from the BIP-341 wallet test vectors:
// https://github.com/bitcoin/bips/blob/master/bip-0341/wallet-test-vectors.json
// sha256 403e19fb81dd1f31e745699216308f61fb403774b2aafa87b631b8f7c042d37f

use shinigami_engine::errors::Error;
use shinigami_engine::flags::ScriptFlags;
use shinigami_engine::taproot;
use shinigami_engine::taproot::ControlBlockTrait;
use shinigami_engine::transaction::{EngineInternalTransactionTrait, EngineTransaction, UTXO};
use shinigami_utils::byte_array::U256IntoByteArray;
use shinigami_utils::bytecode::hex_to_bytecode;
use crate::validate;

fn taproot_flags() -> u32 {
    ScriptFlags::ScriptBip16.into()
        | ScriptFlags::ScriptVerifyWitness.into()
        | ScriptFlags::ScriptVerifyTaproot.into()
}

// Checks one leaf of a script tree: its leaf hash, and that the control block proves the
// script is committed to by the output key.
fn check_leaf(
    control_block_hex: ByteArray, script_hex: ByteArray, output_key: u256, leaf_hash: u256,
) -> Result<(), felt252> {
    let control_block = hex_to_bytecode(@control_block_hex);
    let script = hex_to_bytecode(@script_hex);
    let witness_program: ByteArray = output_key.into();
    let parsed = taproot::parse_control_block(@control_block)?;
    assert_eq!(taproot::tap_hash(@script, parsed.leaf_version), leaf_hash);
    parsed.verify_taproot_leaf(@witness_program, @script)
}

#[test]
fn test_bip341_script_tree_1() {
    check_leaf(
        "0xc1187791b6f712a8ea41c8ecdd0ee77fab3e85263b37e1ec18a3651926b3a6cf27",
        "0x20d85a959b0290bf19bb89ed43c916be835475d013da4b362117393e25a48229b8ac",
        0x147c9c57132f6e7ecddba9800bb0c4449251c92a1e60371ee77557b6620f3ea3,
        0x5b75adecf53548f3ec6ad7d78383bf84cc57b55a3127c72b9a2481752dd88b21,
    )
        .unwrap();
}

#[test]
fn test_bip341_script_tree_2() {
    check_leaf(
        "0xc093478e9488f956df2396be2ce6c5cced75f900dfa18e7dabd2428aae78451820",
        "0x20b617298552a72ade070667e86ca63b8f5789a9fe8731ef91202a91c9f3459007ac",
        0xe4d810fd50586274face62b8a807eb9719cef49c04177cc6b76a9a4251d5450e,
        0xc525714a7f49c28aedbbba78c005931a81c234b2f6c99a73e4d06082adc8bf2b,
    )
        .unwrap();
}

#[test]
fn test_bip341_script_tree_3() {
    check_leaf(
        "0xc0ee4fe085983462a184015d1f782d6a5f8b9c2b60130aff050ce221ecf3786592f224a923cd0021ab202ab139cc56802ddb92dcfc172b9212261a539df79a112a",
        "0x20387671353e273264c495656e27e39ba899ea8fee3bb69fb2a680e22093447d48ac",
        0x712447206d7a5238acc7ff53fbe94a3b64539ad291c7cdbc490b7577e4b17df5,
        0x8ad69ec7cf41c2a4001fd1f738bf1e505ce2277acdcaa63fe4765192497f47a7,
    )
        .unwrap();
    check_leaf(
        "0xfaee4fe085983462a184015d1f782d6a5f8b9c2b60130aff050ce221ecf37865928ad69ec7cf41c2a4001fd1f738bf1e505ce2277acdcaa63fe4765192497f47a7",
        "0x06424950333431",
        0x712447206d7a5238acc7ff53fbe94a3b64539ad291c7cdbc490b7577e4b17df5,
        0xf224a923cd0021ab202ab139cc56802ddb92dcfc172b9212261a539df79a112a,
    )
        .unwrap();
}

#[test]
fn test_bip341_script_tree_4() {
    check_leaf(
        "0xc1f9f400803e683727b14f463836e1e78e1c64417638aa066919291a225f0e8dd82cb2b90daa543b544161530c925f285b06196940d6085ca9474d41dc3822c5cb",
        "0x2044b178d64c32c4a05cc4f4d1407268f764c940d20ce97abfd44db5c3592b72fdac",
        0x77e30a5522dd9f894c3f8b8bd4c4b2cf82ca7da8a3ea6a239655c39c050ab220,
        0x64512fecdb5afa04f98839b50e6f0cb7b1e539bf6f205f67934083cdcc3c8d89,
    )
        .unwrap();
    check_leaf(
        "0xc1f9f400803e683727b14f463836e1e78e1c64417638aa066919291a225f0e8dd864512fecdb5afa04f98839b50e6f0cb7b1e539bf6f205f67934083cdcc3c8d89",
        "0x07546170726f6f74",
        0x77e30a5522dd9f894c3f8b8bd4c4b2cf82ca7da8a3ea6a239655c39c050ab220,
        0x2cb2b90daa543b544161530c925f285b06196940d6085ca9474d41dc3822c5cb,
    )
        .unwrap();
}

#[test]
fn test_bip341_script_tree_5() {
    check_leaf(
        "0xc0e0dfe2300b0dd746a3f8674dfd4525623639042569d829c7f0eed9602d263e6fffe578e9ea769027e4f5a3de40732f75a88a6353a09d767ddeb66accef85e553",
        "0x2072ea6adcf1d371dea8fba1035a09f3d24ed5a059799bae114084130ee5898e69ac",
        0x91b64d5324723a985170e4dc5a0f84c041804f2cd12660fa5dec09fc21783605,
        0x2645a02e0aac1fe69d69755733a9b7621b694bb5b5cde2bbfc94066ed62b9817,
    )
        .unwrap();
    check_leaf(
        "0xc0e0dfe2300b0dd746a3f8674dfd4525623639042569d829c7f0eed9602d263e6f9e31407bffa15fefbf5090b149d53959ecdf3f62b1246780238c24501d5ceaf62645a02e0aac1fe69d69755733a9b7621b694bb5b5cde2bbfc94066ed62b9817",
        "0x202352d137f2f3ab38d1eaa976758873377fa5ebb817372c71e2c542313d4abda8ac",
        0x91b64d5324723a985170e4dc5a0f84c041804f2cd12660fa5dec09fc21783605,
        0xba982a91d4fc552163cb1c0da03676102d5b7a014304c01f0c77b2b8e888de1c,
    )
        .unwrap();
    check_leaf(
        "0xc0e0dfe2300b0dd746a3f8674dfd4525623639042569d829c7f0eed9602d263e6fba982a91d4fc552163cb1c0da03676102d5b7a014304c01f0c77b2b8e888de1c2645a02e0aac1fe69d69755733a9b7621b694bb5b5cde2bbfc94066ed62b9817",
        "0x207337c0dd4253cb86f2c43a2351aadd82cccb12a172cd120452b9bb8324f2186aac",
        0x91b64d5324723a985170e4dc5a0f84c041804f2cd12660fa5dec09fc21783605,
        0x9e31407bffa15fefbf5090b149d53959ecdf3f62b1246780238c24501d5ceaf6,
    )
        .unwrap();
}

#[test]
fn test_bip341_script_tree_6() {
    check_leaf(
        "0xc155adf4e8967fbd2e29f20ac896e60c3b0f1d5b0efa9d34941b5958c7b0a0312d3cd369a528b326bc9d2133cbd2ac21451acb31681a410434672c8e34fe757e91",
        "0x2071981521ad9fc9036687364118fb6ccd2035b96a423c59c5430e98310a11abe2ac",
        0x75169f4001aa68f15bbed28b218df1d0a62cbbcf1188c6665110c293c907b831,
        0xf154e8e8e17c31d3462d7132589ed29353c6fafdb884c5a6e04ea938834f0d9d,
    )
        .unwrap();
    check_leaf(
        "0xc155adf4e8967fbd2e29f20ac896e60c3b0f1d5b0efa9d34941b5958c7b0a0312dd7485025fceb78b9ed667db36ed8b8dc7b1f0b307ac167fa516fe4352b9f4ef7f154e8e8e17c31d3462d7132589ed29353c6fafdb884c5a6e04ea938834f0d9d",
        "0x20d5094d2dbe9b76e2c245a2b89b6006888952e2faa6a149ae318d69e520617748ac",
        0x75169f4001aa68f15bbed28b218df1d0a62cbbcf1188c6665110c293c907b831,
        0x737ed1fe30bc42b8022d717b44f0d93516617af64a64753b7a06bf16b26cd711,
    )
        .unwrap();
    check_leaf(
        "0xc155adf4e8967fbd2e29f20ac896e60c3b0f1d5b0efa9d34941b5958c7b0a0312d737ed1fe30bc42b8022d717b44f0d93516617af64a64753b7a06bf16b26cd711f154e8e8e17c31d3462d7132589ed29353c6fafdb884c5a6e04ea938834f0d9d",
        "0x20c440b462ad48c7a77f94cd4532d8f2119dcebbd7c9764557e62726419b08ad4cac",
        0x75169f4001aa68f15bbed28b218df1d0a62cbbcf1188c6665110c293c907b831,
        0xd7485025fceb78b9ed667db36ed8b8dc7b1f0b307ac167fa516fe4352b9f4ef7,
    )
        .unwrap();
}

#[test]
fn test_bip341_control_block_wrong_parity() {
    let res = check_leaf(
        "0xc1e0dfe2300b0dd746a3f8674dfd4525623639042569d829c7f0eed9602d263e6f9e31407bffa15fefbf5090b149d53959ecdf3f62b1246780238c24501d5ceaf62645a02e0aac1fe69d69755733a9b7621b694bb5b5cde2bbfc94066ed62b9817",
        "0x202352d137f2f3ab38d1eaa976758873377fa5ebb817372c71e2c542313d4abda8ac",
        0x91b64d5324723a985170e4dc5a0f84c041804f2cd12660fa5dec09fc21783605,
        0xba982a91d4fc552163cb1c0da03676102d5b7a014304c01f0c77b2b8e888de1c,
    );
    assert_eq!(res.unwrap_err(), Error::TAPROOT_PARITY_MISMATCH);
}

#[test]
fn test_bip341_control_block_wrong_sibling() {
    let res = check_leaf(
        "0xc0e0dfe2300b0dd746a3f8674dfd4525623639042569d829c7f0eed9602d263e6f9f31407bffa15fefbf5090b149d53959ecdf3f62b1246780238c24501d5ceaf62645a02e0aac1fe69d69755733a9b7621b694bb5b5cde2bbfc94066ed62b9817",
        "0x202352d137f2f3ab38d1eaa976758873377fa5ebb817372c71e2c542313d4abda8ac",
        0x91b64d5324723a985170e4dc5a0f84c041804f2cd12660fa5dec09fc21783605,
        0xba982a91d4fc552163cb1c0da03676102d5b7a014304c01f0c77b2b8e888de1c,
    );
    assert_eq!(res.unwrap_err(), Error::TAPROOT_INVALID_MERKLE_PROOF);
}

#[test]
fn test_bip341_control_block_wrong_internal_key() {
    let res = check_leaf(
        "0xc0f9f400803e683727b14f463836e1e78e1c64417638aa066919291a225f0e8dd89e31407bffa15fefbf5090b149d53959ecdf3f62b1246780238c24501d5ceaf62645a02e0aac1fe69d69755733a9b7621b694bb5b5cde2bbfc94066ed62b9817",
        "0x202352d137f2f3ab38d1eaa976758873377fa5ebb817372c71e2c542313d4abda8ac",
        0x91b64d5324723a985170e4dc5a0f84c041804f2cd12660fa5dec09fc21783605,
        0xba982a91d4fc552163cb1c0da03676102d5b7a014304c01f0c77b2b8e888de1c,
    );
    assert_eq!(res.unwrap_err(), Error::TAPROOT_INVALID_MERKLE_PROOF);
}

#[test]
fn test_bip341_control_block_truncated_path() {
    let res = check_leaf(
        "0xc0e0dfe2300b0dd746a3f8674dfd4525623639042569d829c7f0eed9602d263e6f9e31407bffa15fefbf5090b149d53959ecdf3f62b1246780238c24501d5ceaf6",
        "0x202352d137f2f3ab38d1eaa976758873377fa5ebb817372c71e2c542313d4abda8ac",
        0x91b64d5324723a985170e4dc5a0f84c041804f2cd12660fa5dec09fc21783605,
        0xba982a91d4fc552163cb1c0da03676102d5b7a014304c01f0c77b2b8e888de1c,
    );
    assert_eq!(res.unwrap_err(), Error::TAPROOT_INVALID_MERKLE_PROOF);
}

#[test]
fn test_bip341_control_block_wrong_output_key() {
    let res = check_leaf(
        "0xc0e0dfe2300b0dd746a3f8674dfd4525623639042569d829c7f0eed9602d263e6f9e31407bffa15fefbf5090b149d53959ecdf3f62b1246780238c24501d5ceaf62645a02e0aac1fe69d69755733a9b7621b694bb5b5cde2bbfc94066ed62b9817",
        "0x202352d137f2f3ab38d1eaa976758873377fa5ebb817372c71e2c542313d4abda8ac",
        0x75169f4001aa68f15bbed28b218df1d0a62cbbcf1188c6665110c293c907b831,
        0xba982a91d4fc552163cb1c0da03676102d5b7a014304c01f0c77b2b8e888de1c,
    );
    assert_eq!(res.unwrap_err(), Error::TAPROOT_INVALID_MERKLE_PROOF);
}

#[test]
fn test_bip341_control_block_wrong_script() {
    let control_block = hex_to_bytecode(@"0xc0e0dfe2300b0dd746a3f8674dfd4525623639042569d829c7f0eed9602d263e6f9e31407bffa15fefbf5090b149d53959ecdf3f62b1246780238c24501d5ceaf62645a02e0aac1fe69d69755733a9b7621b694bb5b5cde2bbfc94066ed62b9817");
    let script = hex_to_bytecode(@"0x202352d137f2f3ab38d1eaa976758873377fa5ebb817372c71e2c542313d4abda8ac51");
    let witness_program: ByteArray = 0x91b64d5324723a985170e4dc5a0f84c041804f2cd12660fa5dec09fc21783605_u256.into();
    let parsed = taproot::parse_control_block(@control_block).unwrap();
    let res = parsed.verify_taproot_leaf(@witness_program, @script);
    assert_eq!(res.unwrap_err(), Error::TAPROOT_INVALID_MERKLE_PROOF);
}

fn bip341_transaction() -> EngineTransaction {
    let raw_transaction = hex_to_bytecode(
        @"0x020000000001097de20cbff686da83a54981d2b9bab3586f4ca7e48f57f5b55963115f3b334e9c010000000000000000d7b7cab57b1393ace2d064f4d4a2cb8af6def61273e127517d44759b6dafdd990000000000fffffffff8e1f583384333689228c5d28eac13366be082dc57441760d957275419a41842000000006b4830450221008f3b8f8f0537c420654d2283673a761b7ee2ea3c130753103e08ce79201cf32a022079e7ab904a1980ef1c5890b648c8783f4d10103dd62f740d13daa79e298d50c201210279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798fffffffff0689180aa63b30cb162a73c6d2a38b7eeda2a83ece74310fda0843ad604853b0100000000feffffffaa5202bdf6d8ccd2ee0f0202afbbb7461d9264a25e5bfd3c5a52ee1239e0ba6c0000000000feffffff956149bdc66faa968eb2be2d2faa29718acbfe3941215893a2a3446d32acd050000000000000000000e664b9773b88c09c32cb70a2a3e4da0ced63b7ba3b22f848531bbb1d5d5f4c94010000000000000000e9aa6b8e6c9de67619e6a3924ae25696bb7b694bb677a632a74ef7eadfd4eabf0000000000ffffffffa778eb6a263dc090464cd125c466b5a99667720b1c110468831d058aa1b82af10100000000ffffffff0200ca9a3b000000001976a91406afd46bcdfd22ef94ac122aa11f241244a37ecc88ac807840cb0000000020ac9a87f5594be208f8532db38cff670c450ed2fea8fcdefcc9a663f78bab962b0141ed7c1647cb97379e76892be0cacff57ec4a7102aa24296ca39af7541246d8ff14d38958d4cc1e2e478e4d4a764bbfd835b16d4e314b72937b29833060b87276c030141052aedffc554b41f52b521071793a6b88d6dbca9dba94cf34c83696de0c1ec35ca9c5ed4ab28059bd606a4f3a657eec0bb96661d42921b5f50a95ad33675b54f83000141ff45f742a876139946a149ab4d9185574b98dc919d2eb6754f8abaa59d18b025637a3aa043b91817739554f4ed2026cf8022dbd83e351ce1fabc272841d2510a010140b4010dd48a617db09926f729e79c33ae0b4e94b79f04a1ae93ede6315eb3669de185a17d2b0ac9ee09fd4c64b678a0b61a0a86fa888a273c8511be83bfd6810f0247304402202b795e4de72646d76eab3f0ab27dfa30b810e856ff3a46c9a702df53bb0d8cc302203ccc4d822edab5f35caddb10af1be93583526ccfbade4b4ead350781e2f8adcd012102f9308a019258c31049344f85f89d5229b531c845836f99b08601f113bce036f90141a3785919a2ce3c4ce26f298c3d51619bc474ae24014bcdd31328cd8cfbab2eff3395fa0a16fe5f486d12f22a9cedded5ae74feb4bbe5351346508c5405bcfee0020141ea0c6ba90763c2d3a296ad82ba45881abb4f426b3f87af162dd24d5109edc1cdd11915095ba47c3a9963dc1e6c432939872bc49212fe34c632cd3ab9fed429c4820141bbc9584a11074e83bc8c6759ec55401f0ae7b03ef290c3139814f545b58a9f8127258000874f44bc46db7646322107d4d86aec8e73b8719a61fff761d75b5dd9810065cd1d",
    );
    let utxo_hints = array![
        UTXO {
            amount: 420000000,
            pubkey_script: hex_to_bytecode(@"0x512053a1f6e454df1aa2776a2814a721372d6258050de330b3c6d10ee8f4e0dda343"),
            block_height: 0,
        },
        UTXO {
            amount: 462000000,
            pubkey_script: hex_to_bytecode(@"0x5120147c9c57132f6e7ecddba9800bb0c4449251c92a1e60371ee77557b6620f3ea3"),
            block_height: 0,
        },
        UTXO {
            amount: 294000000,
            pubkey_script: hex_to_bytecode(@"0x76a914751e76e8199196d454941c45d1b3a323f1433bd688ac"),
            block_height: 0,
        },
        UTXO {
            amount: 504000000,
            pubkey_script: hex_to_bytecode(@"0x5120e4d810fd50586274face62b8a807eb9719cef49c04177cc6b76a9a4251d5450e"),
            block_height: 0,
        },
        UTXO {
            amount: 630000000,
            pubkey_script: hex_to_bytecode(@"0x512091b64d5324723a985170e4dc5a0f84c041804f2cd12660fa5dec09fc21783605"),
            block_height: 0,
        },
        UTXO {
            amount: 378000000,
            pubkey_script: hex_to_bytecode(@"0x00147dd65592d0ab2fe0d0257d571abf032cd9db93dc"),
            block_height: 0,
        },
        UTXO {
            amount: 672000000,
            pubkey_script: hex_to_bytecode(@"0x512075169f4001aa68f15bbed28b218df1d0a62cbbcf1188c6665110c293c907b831"),
            block_height: 0,
        },
        UTXO {
            amount: 546000000,
            pubkey_script: hex_to_bytecode(@"0x5120712447206d7a5238acc7ff53fbe94a3b64539ad291c7cdbc490b7577e4b17df5"),
            block_height: 0,
        },
        UTXO {
            amount: 588000000,
            pubkey_script: hex_to_bytecode(@"0x512077e30a5522dd9f894c3f8b8bd4c4b2cf82ca7da8a3ea6a239655c39c050ab220"),
            block_height: 0,
        },
    ];
    EngineInternalTransactionTrait::deserialize(raw_transaction, 0, utxo_hints)
}

fn validate_input(transaction: @EngineTransaction, index: u32) -> Result<(), felt252> {
    let utxo = transaction.utxos.at(index);
    let prevout = UTXO {
        amount: *utxo.amount, pubkey_script: utxo.pubkey_script.clone(), block_height: 0,
    };
    validate::validate_transaction_at(transaction, taproot_flags(), prevout, index)
}

#[test]
fn test_bip341_key_path_input_0_sighash_single() {
    let transaction = bip341_transaction();
    validate_input(@transaction, 0).unwrap();
}

#[test]
fn test_bip341_key_path_input_1_sighash_single_anyonecanpay() {
    let transaction = bip341_transaction();
    validate_input(@transaction, 1).unwrap();
}

#[test]
fn test_bip341_key_path_input_3_sighash_all() {
    let transaction = bip341_transaction();
    validate_input(@transaction, 3).unwrap();
}

#[test]
fn test_bip341_key_path_input_4_sighash_default() {
    let transaction = bip341_transaction();
    validate_input(@transaction, 4).unwrap();
}

#[test]
fn test_bip341_key_path_input_6_sighash_none() {
    let transaction = bip341_transaction();
    validate_input(@transaction, 6).unwrap();
}

#[test]
fn test_bip341_key_path_input_7_sighash_none_anyonecanpay() {
    let transaction = bip341_transaction();
    validate_input(@transaction, 7).unwrap();
}

#[test]
fn test_bip341_key_path_input_8_sighash_all_anyonecanpay() {
    let transaction = bip341_transaction();
    validate_input(@transaction, 8).unwrap();
}

fn bip341_transaction_wrong_amount() -> EngineTransaction {
    let raw_transaction = hex_to_bytecode(
        @"0x020000000001097de20cbff686da83a54981d2b9bab3586f4ca7e48f57f5b55963115f3b334e9c010000000000000000d7b7cab57b1393ace2d064f4d4a2cb8af6def61273e127517d44759b6dafdd990000000000fffffffff8e1f583384333689228c5d28eac13366be082dc57441760d957275419a41842000000006b4830450221008f3b8f8f0537c420654d2283673a761b7ee2ea3c130753103e08ce79201cf32a022079e7ab904a1980ef1c5890b648c8783f4d10103dd62f740d13daa79e298d50c201210279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798fffffffff0689180aa63b30cb162a73c6d2a38b7eeda2a83ece74310fda0843ad604853b0100000000feffffffaa5202bdf6d8ccd2ee0f0202afbbb7461d9264a25e5bfd3c5a52ee1239e0ba6c0000000000feffffff956149bdc66faa968eb2be2d2faa29718acbfe3941215893a2a3446d32acd050000000000000000000e664b9773b88c09c32cb70a2a3e4da0ced63b7ba3b22f848531bbb1d5d5f4c94010000000000000000e9aa6b8e6c9de67619e6a3924ae25696bb7b694bb677a632a74ef7eadfd4eabf0000000000ffffffffa778eb6a263dc090464cd125c466b5a99667720b1c110468831d058aa1b82af10100000000ffffffff0200ca9a3b000000001976a91406afd46bcdfd22ef94ac122aa11f241244a37ecc88ac807840cb0000000020ac9a87f5594be208f8532db38cff670c450ed2fea8fcdefcc9a663f78bab962b0141ed7c1647cb97379e76892be0cacff57ec4a7102aa24296ca39af7541246d8ff14d38958d4cc1e2e478e4d4a764bbfd835b16d4e314b72937b29833060b87276c030141052aedffc554b41f52b521071793a6b88d6dbca9dba94cf34c83696de0c1ec35ca9c5ed4ab28059bd606a4f3a657eec0bb96661d42921b5f50a95ad33675b54f83000141ff45f742a876139946a149ab4d9185574b98dc919d2eb6754f8abaa59d18b025637a3aa043b91817739554f4ed2026cf8022dbd83e351ce1fabc272841d2510a010140b4010dd48a617db09926f729e79c33ae0b4e94b79f04a1ae93ede6315eb3669de185a17d2b0ac9ee09fd4c64b678a0b61a0a86fa888a273c8511be83bfd6810f0247304402202b795e4de72646d76eab3f0ab27dfa30b810e856ff3a46c9a702df53bb0d8cc302203ccc4d822edab5f35caddb10af1be93583526ccfbade4b4ead350781e2f8adcd012102f9308a019258c31049344f85f89d5229b531c845836f99b08601f113bce036f90141a3785919a2ce3c4ce26f298c3d51619bc474ae24014bcdd31328cd8cfbab2eff3395fa0a16fe5f486d12f22a9cedded5ae74feb4bbe5351346508c5405bcfee0020141ea0c6ba90763c2d3a296ad82ba45881abb4f426b3f87af162dd24d5109edc1cdd11915095ba47c3a9963dc1e6c432939872bc49212fe34c632cd3ab9fed429c4820141bbc9584a11074e83bc8c6759ec55401f0ae7b03ef290c3139814f545b58a9f8127258000874f44bc46db7646322107d4d86aec8e73b8719a61fff761d75b5dd9810065cd1d",
    );
    let utxo_hints = array![
        UTXO {
            amount: 420000001,
            pubkey_script: hex_to_bytecode(@"0x512053a1f6e454df1aa2776a2814a721372d6258050de330b3c6d10ee8f4e0dda343"),
            block_height: 0,
        },
        UTXO {
            amount: 462000000,
            pubkey_script: hex_to_bytecode(@"0x5120147c9c57132f6e7ecddba9800bb0c4449251c92a1e60371ee77557b6620f3ea3"),
            block_height: 0,
        },
        UTXO {
            amount: 294000000,
            pubkey_script: hex_to_bytecode(@"0x76a914751e76e8199196d454941c45d1b3a323f1433bd688ac"),
            block_height: 0,
        },
        UTXO {
            amount: 504000000,
            pubkey_script: hex_to_bytecode(@"0x5120e4d810fd50586274face62b8a807eb9719cef49c04177cc6b76a9a4251d5450e"),
            block_height: 0,
        },
        UTXO {
            amount: 630000000,
            pubkey_script: hex_to_bytecode(@"0x512091b64d5324723a985170e4dc5a0f84c041804f2cd12660fa5dec09fc21783605"),
            block_height: 0,
        },
        UTXO {
            amount: 378000000,
            pubkey_script: hex_to_bytecode(@"0x00147dd65592d0ab2fe0d0257d571abf032cd9db93dc"),
            block_height: 0,
        },
        UTXO {
            amount: 672000000,
            pubkey_script: hex_to_bytecode(@"0x512075169f4001aa68f15bbed28b218df1d0a62cbbcf1188c6665110c293c907b831"),
            block_height: 0,
        },
        UTXO {
            amount: 546000000,
            pubkey_script: hex_to_bytecode(@"0x5120712447206d7a5238acc7ff53fbe94a3b64539ad291c7cdbc490b7577e4b17df5"),
            block_height: 0,
        },
        UTXO {
            amount: 588000000,
            pubkey_script: hex_to_bytecode(@"0x512077e30a5522dd9f894c3f8b8bd4c4b2cf82ca7da8a3ea6a239655c39c050ab220"),
            block_height: 0,
        },
    ];
    EngineInternalTransactionTrait::deserialize(raw_transaction, 0, utxo_hints)
}

#[test]
fn test_bip341_key_path_wrong_prevout_amount() {
    let transaction = bip341_transaction_wrong_amount();
    assert_eq!(validate_input(@transaction, 4).unwrap_err(), Error::TAPROOT_INVALID_SIG);
}

fn bip341_transaction_wrong_signature() -> EngineTransaction {
    let raw_transaction = hex_to_bytecode(
        @"0x020000000001097de20cbff686da83a54981d2b9bab3586f4ca7e48f57f5b55963115f3b334e9c010000000000000000d7b7cab57b1393ace2d064f4d4a2cb8af6def61273e127517d44759b6dafdd990000000000fffffffff8e1f583384333689228c5d28eac13366be082dc57441760d957275419a41842000000006b4830450221008f3b8f8f0537c420654d2283673a761b7ee2ea3c130753103e08ce79201cf32a022079e7ab904a1980ef1c5890b648c8783f4d10103dd62f740d13daa79e298d50c201210279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798fffffffff0689180aa63b30cb162a73c6d2a38b7eeda2a83ece74310fda0843ad604853b0100000000feffffffaa5202bdf6d8ccd2ee0f0202afbbb7461d9264a25e5bfd3c5a52ee1239e0ba6c0000000000feffffff956149bdc66faa968eb2be2d2faa29718acbfe3941215893a2a3446d32acd050000000000000000000e664b9773b88c09c32cb70a2a3e4da0ced63b7ba3b22f848531bbb1d5d5f4c94010000000000000000e9aa6b8e6c9de67619e6a3924ae25696bb7b694bb677a632a74ef7eadfd4eabf0000000000ffffffffa778eb6a263dc090464cd125c466b5a99667720b1c110468831d058aa1b82af10100000000ffffffff0200ca9a3b000000001976a91406afd46bcdfd22ef94ac122aa11f241244a37ecc88ac807840cb0000000020ac9a87f5594be208f8532db38cff670c450ed2fea8fcdefcc9a663f78bab962b0141ed7c1647cb97379e76892be0cacff57ec4a7102aa24296ca39af7541246d8ff14d38958d4cc1e2e478e4d4a764bbfd835b16d4e314b72937b29833060b87276c030141052aedffc554b41f52b521071793a6b88d6dbca9dba94cf34c83696de0c1ec35ca9c5ed4ab28059bd606a4f3a657eec0bb96661d42921b5f50a95ad33675b54f83000141ff45f742a876139946a149ab4d9185574b98dc919d2eb6754f8abaa59d18b025637a3aa043b91817739554f4ed2026cf8022dbd83e351ce1fabc272841d2510a010140b4010dd48a617db09926f729e79c33ae0b4e94b79f04a1ae93ede6315eb3669de185a17d2b0ac9ee09fd4c64b678a0b61a0a86fa888a273c8511be83bfd6810e0247304402202b795e4de72646d76eab3f0ab27dfa30b810e856ff3a46c9a702df53bb0d8cc302203ccc4d822edab5f35caddb10af1be93583526ccfbade4b4ead350781e2f8adcd012102f9308a019258c31049344f85f89d5229b531c845836f99b08601f113bce036f90141a3785919a2ce3c4ce26f298c3d51619bc474ae24014bcdd31328cd8cfbab2eff3395fa0a16fe5f486d12f22a9cedded5ae74feb4bbe5351346508c5405bcfee0020141ea0c6ba90763c2d3a296ad82ba45881abb4f426b3f87af162dd24d5109edc1cdd11915095ba47c3a9963dc1e6c432939872bc49212fe34c632cd3ab9fed429c4820141bbc9584a11074e83bc8c6759ec55401f0ae7b03ef290c3139814f545b58a9f8127258000874f44bc46db7646322107d4d86aec8e73b8719a61fff761d75b5dd9810065cd1d",
    );
    let utxo_hints = array![
        UTXO {
            amount: 420000000,
            pubkey_script: hex_to_bytecode(@"0x512053a1f6e454df1aa2776a2814a721372d6258050de330b3c6d10ee8f4e0dda343"),
            block_height: 0,
        },
        UTXO {
            amount: 462000000,
            pubkey_script: hex_to_bytecode(@"0x5120147c9c57132f6e7ecddba9800bb0c4449251c92a1e60371ee77557b6620f3ea3"),
            block_height: 0,
        },
        UTXO {
            amount: 294000000,
            pubkey_script: hex_to_bytecode(@"0x76a914751e76e8199196d454941c45d1b3a323f1433bd688ac"),
            block_height: 0,
        },
        UTXO {
            amount: 504000000,
            pubkey_script: hex_to_bytecode(@"0x5120e4d810fd50586274face62b8a807eb9719cef49c04177cc6b76a9a4251d5450e"),
            block_height: 0,
        },
        UTXO {
            amount: 630000000,
            pubkey_script: hex_to_bytecode(@"0x512091b64d5324723a985170e4dc5a0f84c041804f2cd12660fa5dec09fc21783605"),
            block_height: 0,
        },
        UTXO {
            amount: 378000000,
            pubkey_script: hex_to_bytecode(@"0x00147dd65592d0ab2fe0d0257d571abf032cd9db93dc"),
            block_height: 0,
        },
        UTXO {
            amount: 672000000,
            pubkey_script: hex_to_bytecode(@"0x512075169f4001aa68f15bbed28b218df1d0a62cbbcf1188c6665110c293c907b831"),
            block_height: 0,
        },
        UTXO {
            amount: 546000000,
            pubkey_script: hex_to_bytecode(@"0x5120712447206d7a5238acc7ff53fbe94a3b64539ad291c7cdbc490b7577e4b17df5"),
            block_height: 0,
        },
        UTXO {
            amount: 588000000,
            pubkey_script: hex_to_bytecode(@"0x512077e30a5522dd9f894c3f8b8bd4c4b2cf82ca7da8a3ea6a239655c39c050ab220"),
            block_height: 0,
        },
    ];
    EngineInternalTransactionTrait::deserialize(raw_transaction, 0, utxo_hints)
}

#[test]
fn test_bip341_key_path_wrong_signature() {
    let transaction = bip341_transaction_wrong_signature();
    assert_eq!(validate_input(@transaction, 4).unwrap_err(), Error::TAPROOT_INVALID_SIG);
    // The other inputs are unaffected.
    validate_input(@transaction, 3).unwrap();
}
