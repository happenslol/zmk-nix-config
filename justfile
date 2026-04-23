build name:
    mkdir -p build
    nix build .#{{name}} -o build/{{name}}

clean:
    rm -rf build
