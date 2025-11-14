#!/bin/bash

set -xeuo pipefail

# Install the hipify-perl script
install -D -m 755 bin/hipify-perl "${PREFIX}/bin/hipify-perl"
