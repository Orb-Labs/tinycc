{
  description = "A very basic flake";

  outputs = { self, nixpkgs }: {

    packages.x86_64-linux.tinycc =
      with import nixpkgs { system = "x86_64-linux"; };
      stdenv.mkDerivation {
        name = "tinycc";
        src = self;
        nativeBuildInputs = [ perl texinfo which ];
        configureFlags = [
          "--cc=cc"
          "--crtprefix=${lib.getLib stdenv.cc.libc}/lib"
          "--sysincludepaths=${lib.getDev stdenv.cc.libc}/include:{B}/include"
          "--libpaths=${lib.getLib stdenv.cc.libc}/lib"
          # build cross compilers
          "--enable-cross"
        ];
      };

    defaultPackage.x86_64-linux = self.packages.x86_64-linux.tinycc;

  };
}
