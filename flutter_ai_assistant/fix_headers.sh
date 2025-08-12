#!/bin/bash

# Fix Firebase and GoogleUtilities header include issues for Xcode 16.2
echo "Fixing header include issues for Xcode 16.2 compatibility..."

# Navigate to the iOS directory
cd ios

# Fix double-quoted includes in umbrella headers
echo "Fixing umbrella headers..."
find Pods/Target\ Support\ Files -name "*-umbrella.h" -type f -exec sed -i '' 's/#import "/#import </g; s/\.h"/.h>/g' {} \;

# Fix double-quoted includes in Firebase headers
echo "Fixing Firebase headers..."
find Pods/FirebaseCore -name "*.h" -type f -exec sed -i '' 's/#import "/#import </g; s/\.h"/.h>/g' {} \;

# Fix double-quoted includes in GoogleUtilities headers
echo "Fixing GoogleUtilities headers..."
find Pods/GoogleUtilities -name "*.h" -type f -exec sed -i '' 's/#import "/#import </g; s/\.h"/.h>/g' {} \;

# Fix double-quoted includes in PromisesObjC headers
echo "Fixing PromisesObjC headers..."
find Pods/PromisesObjC -name "*.h" -type f -exec sed -i '' 's/#import "/#import </g; s/\.h"/.h>/g' {} \;

# Fix any remaining double-quoted includes in all pods
echo "Fixing remaining headers..."
find Pods -name "*.h" -type f -exec sed -i '' 's/#import "FBL/#import <FBL/g; s/#import "FIR/#import <FIR/g; s/#import "GUL/#import <GUL/g' {} \;

echo "Header fixes completed!"
