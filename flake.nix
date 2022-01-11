{
  description = "The Tiny C compiler";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-21.11";

  nixConfig.bash-prompt = "[tinycc] $ ";

  outputs = { self, nixpkgs }:
  let pkgs = import nixpkgs { system = "x86_64-linux"; };
      devDeps = with pkgs; [ perl texinfo which ];
  in
  {

    packages.x86_64-linux.tinycc =
      with pkgs;
      stdenv.mkDerivation {
        name = "tinycc";
        src = self;
        nativeBuildInputs = devDeps;
        configureFlags = [
          "--cc=cc"
          "--crtprefix=${lib.getLib stdenv.cc.libc}/lib"
          "--sysincludepaths=${lib.getDev stdenv.cc.libc}/include:{B}/include"
          "--libpaths=${lib.getLib stdenv.cc.libc}/lib"
          "--elfinterp=${stdenv.cc.outPath}/nix-support/dynamic-linker"
          # build cross compilers
          "--enable-cross"
        ];

        checkPhase = ''
          make test
        '';
      };

    defaultPackage.x86_64-linux = self.packages.x86_64-linux.tinycc;

    devShell.x86_64-linux =
      with pkgs;
      let prefix = lib.getLib stdenv.cc.libc;
          devPrefix = lib.getDev stdenv.cc.libc;
      in
      mkShell {
        nativeBuildInputs = devDeps;
        shellHook = ''
          echo "prefix is" ${prefix}
          echo "dev prefix is" ${devPrefix}
          ./configure --cc=cc --crtprefix=${prefix}/lib \
            --sysincludepaths=${devPrefix}/include:{B}/include \
            --libpaths=${prefix}/lib \
            --prefix=./local \
            --enable-cross \
            --elfinterp=$(< ${stdenv.cc.outPath}/nix-support/dynamic-linker)
          echo "Welcome to TinyCC dev shell!"
        '';
      };
  };
}
