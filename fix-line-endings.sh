#!/bin/bash
# Fix line endings for all shell scripts

echo "Fixing line endings for shell scripts..."

# Convert CRLF to LF for all .sh files
find . -name "*.sh" -type f -exec sed -i 's/\r$//' {} \;

echo "✅ Done! All .sh files now have Unix line endings (LF)"
echo ""
echo "You can now run:"
echo "  chmod +x setup.sh cleanup.sh"
echo "  ./setup.sh"
