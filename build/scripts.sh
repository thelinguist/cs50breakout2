!# /bin/bash

# Build
zip -9 -r build/filthyBird.love . -x "build/*" -x ".idea/*" -x "*/.DS_Store"


# Run
open -n -a love .
