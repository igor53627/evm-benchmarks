#!/bin/bash
# evmone runner for EVM benchmarks
# Uses the evmc CLI tool with libevmone.so

# Default paths for hsiao build server
EVMONE_LIB="${EVMONE_LIB:-/root/evmone/build/lib/libevmone.so}"
EVMC_TOOL="${EVMC_TOOL:-/root/evmone/evmc/build/bin/evmc}"

# Parse arguments
BYTECODE=""
CALLDATA=""
GAS_LIMIT=30000000
INTERNAL_RUNS=1
MEASURE_STARTUP=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --bytecode)
            BYTECODE="$2"
            shift 2
            ;;
        --calldata)
            CALLDATA="$2"
            shift 2
            ;;
        --gas-limit)
            GAS_LIMIT="$2"
            shift 2
            ;;
        --internal-runs)
            INTERNAL_RUNS="$2"
            shift 2
            ;;
        --measure-startup)
            MEASURE_STARTUP=true
            shift
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

if [[ -z "$BYTECODE" ]]; then
    echo "Error: --bytecode is required" >&2
    exit 1
fi

# Exit early if measuring startup overhead
if [[ "$MEASURE_STARTUP" == "true" ]]; then
    exit 0
fi

# Strip 0x prefix if present for evmc tool
BYTECODE_CLEAN="${BYTECODE#0x}"
BYTECODE_CLEAN="${BYTECODE_CLEAN#0X}"

# Build input argument
INPUT_ARG=""
if [[ -n "$CALLDATA" ]]; then
    CALLDATA_CLEAN="${CALLDATA#0x}"
    CALLDATA_CLEAN="${CALLDATA_CLEAN#0X}"
    INPUT_ARG="--input $CALLDATA_CLEAN"
fi

# Run the benchmark
for ((i=0; i<INTERNAL_RUNS; i++)); do
    # Run evmone via evmc tool
    OUTPUT=$(EVMC_VM="$EVMONE_LIB" "$EVMC_TOOL" run --gas "$GAS_LIMIT" $INPUT_ARG "$BYTECODE_CLEAN" 2>&1)
    
    # Parse output for success and gas used
    if echo "$OUTPUT" | grep -q "Result:.*success"; then
        echo "true"
        GAS_USED=$(echo "$OUTPUT" | grep "Gas used:" | awk '{print $3}')
        echo "${GAS_USED:-0}"
    else
        echo "false"
        echo "0"
        # Show error on first failure
        if [[ $i -eq 0 ]]; then
            echo "$OUTPUT" >&2
        fi
    fi
done
