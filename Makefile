test:
	forge test

test-fork:
	forge test --fork-url https://mainnet.base.org

build:
	forge clean && forge build && forge test --ffi -vvv