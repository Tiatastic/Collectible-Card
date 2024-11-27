# Collectible Card Game Smart Contract

## Overview

This Clarity smart contract implements a decentralized Collectible Card Game (CCG) on the Stacks blockchain. It allows players to mint, trade, battle, and purchase digital collectible cards. The game leverages blockchain technology to ensure true ownership and scarcity of in-game assets.

## Features

- Card Minting: Create new cards with unique attributes
- Card Ownership: Track card ownership on the blockchain
- Card Transfers: Allow players to transfer cards to others
- Card Battles: Implement a simple battle mechanism between cards
- Card Marketplace: Enable buying and selling of cards using STX
- Game Pause/Resume: Admin functionality to pause and resume game operations
- Ownership Transfer: Allow transfer of contract ownership

## Contract Details

- File: \`collectible-card-game.clar\`
- Language: Clarity
- Blockchain: Stacks

## Usage

### Admin Functions

- \`mint-new-card\`: Create a new card (only contract owner)
- \`pause-game-operations\`: Pause all game operations (only contract owner)
- \`resume-game-operations\`: Resume game operations (only contract owner)
- \`transfer-contract-ownership\`: Transfer contract ownership (only contract owner)

### Player Functions

- \`transfer-card\`: Transfer a card to another player
- \`initiate-card-battle\`: Battle your card against another player's card
- \`purchase-card\`: Buy a card from another player

### Read-Only Functions

- \`get-card-info\`: Get details of a specific card
- \`get-player-balance\`: Get the STX balance of a player
- \`get-player-cards\`: Get the list of cards owned by a player

## Example Interactions

Here are some example interactions with the contract using the Clarity console:

1. Mint a new card (as contract owner):
   \`\`\`
   (contract-call? .collectible-card-game mint-new-card "Mighty Dragon" u100 u80 u5 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
   \`\`\`

2. Transfer a card:
   \`\`\`
   (contract-call? .collectible-card-game transfer-card u1 'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG)
   \`\`\`

3. Initiate a card battle:
   \`\`\`
   (contract-call? .collectible-card-game initiate-card-battle u1 u2)
   \`\`\`

4. Purchase a card:
   \`\`\`
   (contract-call? .collectible-card-game purchase-card u3 u1000)
   \`\`\`

## Security Considerations

- The contract includes access control mechanisms to ensure only the owner can perform certain actions.
- Players should be cautious when approving transactions and ensure they're interacting with the correct contract.
- The battle mechanism is simple and deterministic. Future versions may implement more complex battle logic.