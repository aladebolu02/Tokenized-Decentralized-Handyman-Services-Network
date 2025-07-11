# Tokenized Decentralized Handyman Services Network

A blockchain-based platform for connecting homeowners with verified contractors, built on the Stacks blockchain using Clarity smart contracts.

## Overview

This decentralized network provides a comprehensive solution for handyman services with built-in verification, estimation, quality control, material sourcing, and warranty tracking.

## Smart Contracts

### 1. Skill Verification Contract (`skill-verification.clar`)
- Validates contractor expertise in specific repair areas
- Manages skill certifications and endorsements
- Tracks contractor reputation scores
- Handles skill verification processes

### 2. Project Estimation Contract (`project-estimation.clar`)
- Provides accurate cost and timeline assessments
- Manages project proposals and bids
- Tracks estimation accuracy over time
- Handles project scope definitions

### 3. Quality Inspection Contract (`quality-inspection.clar`)
- Ensures completed work meets professional standards
- Manages inspection processes and results
- Tracks quality metrics and ratings
- Handles dispute resolution for quality issues

### 4. Material Sourcing Contract (`material-sourcing.clar`)
- Manages hardware and supply procurement
- Tracks material costs and availability
- Handles supplier relationships
- Manages inventory and delivery tracking

### 5. Warranty Tracking Contract (`warranty-tracking.clar`)
- Handles service guarantees and follow-up maintenance
- Manages warranty periods and claims
- Tracks maintenance schedules
- Handles warranty dispute resolution

## Features

- **Decentralized Verification**: Contractors can prove their skills through blockchain-verified certifications
- **Transparent Pricing**: All estimates and costs are recorded on-chain for transparency
- **Quality Assurance**: Built-in inspection and rating system ensures work quality
- **Supply Chain Management**: Integrated material sourcing with cost tracking
- **Warranty Protection**: Automated warranty tracking and claim processing

## Token Economics

The network uses a native token for:
- Staking for contractor verification
- Payment for services
- Incentivizing quality work
- Governance participation

## Getting Started

### Prerequisites
- Clarinet CLI installed
- Node.js for running tests
- Stacks wallet for interaction

### Installation

1. Clone the repository
2. Install dependencies: `npm install`
3. Run tests: `npm test`
4. Deploy contracts: `clarinet deploy`

### Usage

1. **Contractors**: Register skills, submit estimates, complete work
2. **Homeowners**: Post projects, review bids, approve work
3. **Inspectors**: Verify work quality, resolve disputes
4. **Suppliers**: Manage material inventory, fulfill orders

## Testing

Tests are written using Vitest and cover all contract functionality:

\`\`\`
npm test
\`\`\`

## Contract Interactions

Each contract operates independently without cross-contract calls, ensuring modularity and security.

## Security Considerations

- All contracts include proper access controls
- Input validation on all public functions
- Protection against common attack vectors
- Comprehensive error handling

## Contributing

Please read CONTRIBUTING.md for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
