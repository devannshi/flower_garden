#!/bin/bash

# Test script for Greedy Planting Algorithm using main.py (main project runner)
# 
# This script tests the algorithm through the official main.py interface.
# For standalone testing with detailed output, use test.sh instead.
#
# Usage: ./test_main.sh
# 
# Configuration: Edit variables below

# uv run python main.py --json_path /path/to/my.json --turns 200 --gardener gr
# uv run python main.py --json_path gardeners/group10/config/test.json --turns 100 --gardener g10 --gui

cd "$(dirname "$0")/../.."

# ========== CONFIGURATION ==========
CONFIG="gardeners/group10/config/test.json"  # Options: test.json, easy.json
TURNS=100                                     # Number of simulation turns
GUI_ON=true                                  # Set to true to enable GUI visualization

# Available configs:
# - test.json: 6 varieties (3 Rhododendron, 2 Geranium, 1 Begonia)
# - easy.json: 30 varieties (10 of each species)
# ===================================

echo "=========================================="
echo "Testing Group 10 Greedy Planting Algorithm"
echo "=========================================="
echo "Config: $CONFIG"
echo "Turns: $TURNS"
echo "GUI: $GUI_ON"
echo ""

# Run test
if [ "$GUI_ON" = true ]; then
    uv run python main.py \
        --json_path "$CONFIG" \
        --turns "$TURNS" \
        --gardener g10 \
        --gui
else
    uv run python main.py \
        --json_path "$CONFIG" \
        --turns "$TURNS" \
        --gardener g10
fi

echo ""
echo "=========================================="
echo "Test Complete"
echo "=========================================="

