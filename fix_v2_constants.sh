#!/bin/bash

# Fix all V2 files to use the adapter constants

V2_FILES=$(find ./lib -name "*_v2.dart" -type f)

for file in $V2_FILES; do
    echo "Processing $file..."
    
    # Check if file uses spacing or text constants
    if grep -q "SpacingConsts\.[slm]\|TextConsts\.body" "$file"; then
        # Add import if not already present
        if ! grep -q "v2_constants_adapter.dart" "$file"; then
            # Find the last import line and add the adapter import after it
            sed -i '' '/^import.*\.dart.;$/h; /^import.*\.dart.;$/!H; $!d; x; s/\(.*\)\(import.*\.dart.;\)/\1\2\nimport '\''..\/..\/..\/..\/core\/utils\/v2_constants_adapter.dart'\'';/' "$file"
        fi
        
        # Replace constants
        sed -i '' 's/SpacingConsts\.l/SpacingConstsV2.l/g' "$file"
        sed -i '' 's/SpacingConsts\.m/SpacingConstsV2.m/g' "$file"
        sed -i '' 's/SpacingConsts\.s/SpacingConstsV2.s/g' "$file"
        sed -i '' 's/TextConsts\.body/TextConstsV2.body/g' "$file"
    fi
done

echo "Done!"