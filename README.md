# SagaSpell 🧙‍♂️✨

A magical spell casting smart contract built on the Stacks blockchain using Clarity. SagaSpell allows users to create, own, trade, and cast spells with different powers, rarities, and magical effects.

## Features

- **Spell Creation**: Users can create custom spells with unique names, descriptions, power levels, and rarities
- **Mana System**: Energy-based casting system with automatic mana regeneration over time
- **Spell Ownership**: Spells are owned as NFT-like assets that can be transferred between users
- **Cooldown Mechanics**: Spells have cooldown periods to prevent spam casting
- **Rarity System**: Spells can have different rarity levels (Common, Rare, Epic, Legendary)
- **Power Scaling**: Spells have different power levels affecting their mana cost and effectiveness

## Smart Contract Functions

### Public Functions

#### `initialize-user`
Initialize a new user account with starting mana (100) and empty spell collection.

#### `create-spell`
Create a new spell with the following parameters:
- `name`: Spell name (max 50 characters)
- `description`: Spell description (max 200 characters)
- `power`: Spell power level (uint)
- `mana-cost`: Mana required to cast (uint)
- `rarity`: Spell rarity level (string)
- `cooldown-blocks`: Blocks to wait between casts (uint)

#### `cast-spell`
Cast a spell by its ID. Requires sufficient mana and spell must not be on cooldown.

#### `transfer-spell`
Transfer spell ownership to another user. Only the current owner can transfer.

### Read-Only Functions

#### `get-spell`
Get detailed information about a specific spell.

#### `get-user`
Get user account information including mana and spell statistics.

#### `get-user-mana`
Get user's current mana with regeneration calculated.

#### `get-spell-owner`
Get the current owner of a specific spell.

#### `check-spell-cooldown`
Check if a spell is currently on cooldown for a specific user.

#### `get-total-spells`
Get the total number of spells created in the contract.

## Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) - Stacks smart contract development tool
- [Node.js](https://nodejs.org/) - For running tests

### Installation

1. Clone the repository:
```bash
git clone https://github.com/teefeh-07/SagaSpell.git
cd SagaSpell
```

2. Install Clarinet (if not already installed):
```bash
# On macOS
brew install clarinet

# On other platforms, see: https://github.com/hirosystems/clarinet#installation
```

### Development

1. Check the project:
```bash
clarinet check
```

2. Run tests:
```bash
clarinet test
```

3. Start a local development environment:
```bash
clarinet integrate
```

## Usage Examples

### Creating Your First Spell

```clarity
;; Initialize your user account first
(contract-call? .Saga initialize-user)

;; Create a fireball spell
(contract-call? .Saga create-spell 
  "Fireball" 
  "A blazing ball of fire that burns enemies" 
  u100 
  u25 
  "Common" 
  u5)
```

### Casting a Spell

```clarity
;; Cast spell with ID 1
(contract-call? .Saga cast-spell u1)
```

### Transferring a Spell

```clarity
;; Transfer spell ID 1 to another user
(contract-call? .Saga transfer-spell u1 'ST1SJ3DTE5DN7X54YDH5D64R3BCB6A2AG2ZQ8YPD5)
```

## Game Mechanics

### Mana System
- Users start with 100 mana
- Mana regenerates at 1 point per 10 blocks
- Maximum mana capacity is 1000
- Spells consume mana based on their power level

### Spell Cooldowns
- Each spell has a cooldown period measured in blocks
- Users must wait for the cooldown to expire before recasting
- Cooldowns are per-user, per-spell

### Spell Rarity Suggestions
- **Common**: Basic spells, low mana cost (10-30)
- **Rare**: Moderate spells, medium mana cost (30-60)
- **Epic**: Powerful spells, high mana cost (60-100)
- **Legendary**: Ultimate spells, very high mana cost (100+)

## Testing

The project includes comprehensive tests covering:
- User initialization
- Spell creation and validation
- Spell casting mechanics
- Mana management
- Cooldown systems
- Ownership transfers
- Error handling

Run all tests:
```bash
clarinet test
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-spell`)
3. Commit your changes (`git commit -m 'Add amazing spell feature'`)
4. Push to the branch (`git push origin feature/amazing-spell`)
5. Open a Pull Request

## License

This project is open source and available under the [MIT License](LICENSE).

## Roadmap

- [ ] Spell battles between users
- [ ] Spell crafting and combination system
- [ ] Marketplace for spell trading
- [ ] Guild system for collaborative spell casting
- [ ] Achievement system for spell masters
- [ ] Integration with Stacks NFT standards

## Support

If you have questions or need help, please:
1. Check the [Issues](https://github.com/teefeh-07/SagaSpell/issues) page
2. Create a new issue if your question isn't answered
3. Join the Stacks community Discord for general Clarity development help

---

Built with ❤️ on the Stacks blockchain using Clarity smart contracts.
