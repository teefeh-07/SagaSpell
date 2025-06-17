
import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v0.31.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "User can initialize their account",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;

        let block = chain.mineBlock([
            Tx.contractCall('Saga', 'initialize-user', [], wallet1.address)
        ]);

        assertEquals(block.receipts.length, 1);
        assertEquals(block.receipts[0].result, `(ok "User initialized successfully")`);

        // Check user data
        let userQuery = chain.callReadOnlyFn('Saga', 'get-user', [types.principal(wallet1.address)], wallet1.address);
        assertEquals(userQuery.result.includes('mana: u100'), true);
    },
});

Clarinet.test({
    name: "User can create a spell",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;

        let block = chain.mineBlock([
            Tx.contractCall('Saga', 'initialize-user', [], wallet1.address),
            Tx.contractCall('Saga', 'create-spell', [
                types.ascii("Fireball"),
                types.ascii("A powerful fire spell that deals massive damage"),
                types.uint(100),
                types.uint(25),
                types.ascii("Common"),
                types.uint(5)
            ], wallet1.address)
        ]);

        assertEquals(block.receipts.length, 2);
        assertEquals(block.receipts[1].result, `(ok u1)`);

        // Check spell was created
        let spellQuery = chain.callReadOnlyFn('Saga', 'get-spell', [types.uint(1)], wallet1.address);
        assertEquals(spellQuery.result.includes('name: "Fireball"'), true);
        assertEquals(spellQuery.result.includes('power: u100'), true);
    },
});

Clarinet.test({
    name: "User can cast a spell",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;

        let block = chain.mineBlock([
            Tx.contractCall('Saga', 'initialize-user', [], wallet1.address),
            Tx.contractCall('Saga', 'create-spell', [
                types.ascii("Lightning Bolt"),
                types.ascii("A quick lightning attack"),
                types.uint(75),
                types.uint(20),
                types.ascii("Common"),
                types.uint(3)
            ], wallet1.address)
        ]);

        // Cast the spell
        block = chain.mineBlock([
            Tx.contractCall('Saga', 'cast-spell', [types.uint(1)], wallet1.address)
        ]);

        assertEquals(block.receipts.length, 1);
        assertEquals(block.receipts[0].result.includes('spell-name: "Lightning Bolt"'), true);
        assertEquals(block.receipts[0].result.includes('power: u75'), true);

        // Check mana was deducted
        let userQuery = chain.callReadOnlyFn('Saga', 'get-user-mana', [types.principal(wallet1.address)], wallet1.address);
        assertEquals(userQuery.result, `u80`); // 100 - 20 = 80
    },
});

Clarinet.test({
    name: "User cannot cast spell without enough mana",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;

        let block = chain.mineBlock([
            Tx.contractCall('Saga', 'initialize-user', [], wallet1.address),
            Tx.contractCall('Saga', 'create-spell', [
                types.ascii("Meteor"),
                types.ascii("Devastating meteor strike"),
                types.uint(500),
                types.uint(150), // More than initial mana
                types.ascii("Legendary"),
                types.uint(10)
            ], wallet1.address)
        ]);

        // Try to cast the spell
        block = chain.mineBlock([
            Tx.contractCall('Saga', 'cast-spell', [types.uint(1)], wallet1.address)
        ]);

        assertEquals(block.receipts.length, 1);
        assertEquals(block.receipts[0].result, `(err u102)`); // ERR-INSUFFICIENT-MANA
    },
});

Clarinet.test({
    name: "Spell cooldown prevents immediate recasting",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;

        let block = chain.mineBlock([
            Tx.contractCall('Saga', 'initialize-user', [], wallet1.address),
            Tx.contractCall('Saga', 'create-spell', [
                types.ascii("Ice Shard"),
                types.ascii("Sharp ice projectile"),
                types.uint(50),
                types.uint(15),
                types.ascii("Common"),
                types.uint(5) // 5 block cooldown
            ], wallet1.address)
        ]);

        // Cast the spell first time
        block = chain.mineBlock([
            Tx.contractCall('Saga', 'cast-spell', [types.uint(1)], wallet1.address)
        ]);
        assertEquals(block.receipts[0].result.includes('ok'), true);

        // Try to cast immediately again
        block = chain.mineBlock([
            Tx.contractCall('Saga', 'cast-spell', [types.uint(1)], wallet1.address)
        ]);
        assertEquals(block.receipts[0].result, `(err u103)`); // ERR-SPELL-ON-COOLDOWN
    },
});

Clarinet.test({
    name: "User can transfer spell ownership",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        const wallet2 = accounts.get('wallet_2')!;

        let block = chain.mineBlock([
            Tx.contractCall('Saga', 'initialize-user', [], wallet1.address),
            Tx.contractCall('Saga', 'initialize-user', [], wallet2.address),
            Tx.contractCall('Saga', 'create-spell', [
                types.ascii("Heal"),
                types.ascii("Restore health"),
                types.uint(30),
                types.uint(10),
                types.ascii("Common"),
                types.uint(2)
            ], wallet1.address)
        ]);

        // Transfer spell to wallet2
        block = chain.mineBlock([
            Tx.contractCall('Saga', 'transfer-spell', [
                types.uint(1),
                types.principal(wallet2.address)
            ], wallet1.address)
        ]);

        assertEquals(block.receipts.length, 1);
        assertEquals(block.receipts[0].result, `(ok true)`);

        // Check new owner
        let ownerQuery = chain.callReadOnlyFn('Saga', 'get-spell-owner', [types.uint(1)], wallet1.address);
        assertEquals(ownerQuery.result.includes(wallet2.address), true);
    },
});

Clarinet.test({
    name: "Non-owner cannot transfer spell",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        const wallet2 = accounts.get('wallet_2')!;

        let block = chain.mineBlock([
            Tx.contractCall('Saga', 'initialize-user', [], wallet1.address),
            Tx.contractCall('Saga', 'initialize-user', [], wallet2.address),
            Tx.contractCall('Saga', 'create-spell', [
                types.ascii("Shield"),
                types.ascii("Protective barrier"),
                types.uint(40),
                types.uint(12),
                types.ascii("Common"),
                types.uint(3)
            ], wallet1.address)
        ]);

        // Try to transfer spell from wallet2 (not owner)
        block = chain.mineBlock([
            Tx.contractCall('Saga', 'transfer-spell', [
                types.uint(1),
                types.principal(wallet2.address)
            ], wallet2.address)
        ]);

        assertEquals(block.receipts.length, 1);
        assertEquals(block.receipts[0].result, `(err u105)`); // ERR-UNAUTHORIZED
    },
});
