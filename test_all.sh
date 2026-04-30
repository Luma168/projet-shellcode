#!/bin/bash
# Teste chaque variante avec le shellcode exit(42)
# Place ce script dans la racine du projet et exécute-le.
#
echo "=== Test normal ==="
python3 uwu_cli.py generate --hex "6a3c586a2a5f0f05" -o test_normal.bin
ln -sf test_normal.bin out.bin
./tester ; echo "Exit: $?"

echo "=== Test XOR ==="
python3 uwu_cli.py generate --hex "6a3c586a2a5f0f05" --xor -o test_xor.bin
ln -sf test_xor.bin out.bin
./tester ; echo "Exit: $?"

echo "=== Test Reverse ==="
python3 uwu_cli.py generate --hex "6a3c586a2a5f0f05" --reverse -o test_reverse.bin
ln -sf test_reverse.bin out.bin
./tester ; echo "Exit: $?"

echo "=== Test Double XOR ==="
python3 uwu_cli.py generate --hex "6a3c586a2a5f0f05" --double -o test_double.bin
ln -sf test_double.bin out.bin
./tester ; echo "Exit: $?"
