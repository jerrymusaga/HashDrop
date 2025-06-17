
# HashDrop Platform Makefile

# Default target
.PHONY: help
help:
	@echo "HashDrop Platform Build Commands"
	@echo "================================="
	@echo "install     - Install dependencies"
	@echo "build       - Build contracts"  
	@echo "test        - Run tests"
	@echo "clean       - Clean build artifacts"
	@echo "deploy-fuji - Deploy to Fuji testnet"
	@echo "deploy-avax - Deploy to Avalanche mainnet"
	@echo "verify      - Verify deployed contracts"
	@echo "test-campaign - Create test campaign"

# Install dependencies
.PHONY: install
install:
	forge install foundry-rs/forge-std
	forge install OpenZeppelin/openzeppelin-contracts
	forge install smartcontractkit/chainlink-brownie-contracts

# Build contracts
.PHONY: build
build:
	forge build

# Run tests
.PHONY: test
test:
	forge test -vvv

# Clean build artifacts
.PHONY: clean
clean:
	forge clean

# Deploy to Fuji testnet
.PHONY: deploy-fuji
deploy-fuji:
	@echo "Deploying to Avalanche Fuji testnet..."
	forge script script/HashDropDeploy.s.sol \
		--rpc-url $(FUJI_RPC_URL) \
		--private-key $(PRIVATE_KEY) \
		--broadcast \
		--verify \
		--verifier-url https://api-testnet.snowtrace.io/api \
		--etherscan-api-key $(ETHERSCAN_API_KEY)

# Deploy to Avalanche mainnet
.PHONY: deploy-avax
deploy-avax:
	@echo "⚠️  Deploying to Avalanche MAINNET!"
	@echo "Press Ctrl+C to cancel, or Enter to continue..."
	@read
	forge script script/HashDropDeploy.s.sol \
		--rpc-url $(AVALANCHE_RPC_URL) \
		--private-key $(PRIVATE_KEY) \
		--broadcast \
		--verify \
		--verifier-url https://api.snowtrace.io/api \
		--etherscan-api-key $(ETHERSCAN_API_KEY)

# Verify contracts
.PHONY: verify
verify:
	forge script script/VerifyContracts.s.sol \
		--rpc-url $(FUJI_RPC_URL) \
		--private-key $(PRIVATE_KEY)

# Create test campaign
.PHONY: test-campaign
test-campaign:
	forge script script/TestCampaign.s.sol \
		--rpc-url $(FUJI_RPC_URL) \
		--private-key $(PRIVATE_KEY) \
		--broadcast

# Gas report
.PHONY: gas-report
gas-report:
	forge test --gas-report

# Coverage report
.PHONY: coverage
coverage:
	forge coverage

# Format code
.PHONY: format
format:
	forge fmt

# Lint code
.PHONY: lint
lint:
	forge fmt --check

# Generate documentation
.PHONY: docs
docs:
	forge doc

# Update dependencies
.PHONY: update
update:
	forge update