build name:
    mkdir -p build
    nix build .#{{name}} -o build/{{name}}

flash name: (build name)
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -f build/{{name}}/zmk_left.uf2 ] && [ -f build/{{name}}/zmk_right.uf2 ]; then
        ./flash.sh {{name}} left
        ./flash.sh {{name}} right
    else
        ./flash.sh {{name}}
    fi

clean:
    rm -rf build
