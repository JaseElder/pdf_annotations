
#!/bin/bash

# Run tests and generate coverage
flutter test --coverage

# Use flutter's built-in tool or standard tools to remove files
# (This requires the remove_from_coverage package from Option 1)
remove_from_coverage -f coverage/lcov.info -r '\.g\.dart$|\.mocks\.dart$|\.form\.dart$|brick/db/.*|generated/.*'

# Optional: Generate an HTML report
genhtml coverage/lcov.info -o coverage/html

echo "Coverage report generated in coverage/html"