{
  description = "The Tiny C compiler";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-21.11";
    flake-compat-ci.url = "github:hercules-ci/flake-compat-ci";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
  };

  nixConfig.bash-prompt = "[tinycc] $ ";

  outputs = { self, nixpkgs, flake-compat, flake-compat-ci}:
  let pkgs = import nixpkgs { system = "x86_64-linux"; };
      devDeps = with pkgs; [ perl texinfo which ];
  in
  {
    #CI integration
    ciNix = flake-compat-ci.lib.recurseIntoFlakeWith {
      flake = self;
      systems = [ "x86_64-linux" ];
    };

    packages.x86_64-linux.tinycc =
      with pkgs;
      stdenv.mkDerivation {
        name = "tinycc";
        src = self;
        nativeBuildInputs = devDeps;
        preConfigure = ''
          configureFlagsArray+=("--elfinterp=$(< ${stdenv.cc.outPath}/nix-support/dynamic-linker)")
        '';
        configureFlags = [
          "--cc=cc"
          "--crtprefix=${lib.getLib stdenv.cc.libc}/lib"
          "--sysincludepaths=${lib.getDev stdenv.cc.libc}/include:{B}/include"
          "--libpaths=${lib.getLib stdenv.cc.libc}/lib"
          # build cross compilers
          "--enable-cross"
        ];

        doCheck = true;

        checkPhase = ''
          make
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
