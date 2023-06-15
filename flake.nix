{
  description = "A script/library to create, launch and remove an Scylla / Apache Cassandra cluster on
localhost.";

  inputs = {
    nixpkgs.url = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      make_ccm_package = {pkgs, doCheck ? false} : pkgs.python3Packages.buildPythonApplication {
        inherit doCheck;

        pname = "scylla_ccm";
        version = "0.1";

        src = ./. ;

        checkInputs = with pkgs.python3Packages; [ pytestCheckHook ];
        propagatedBuildInputs =  with pkgs.python3Packages; [ pyyaml psutil six requests packaging boto3 tqdm setuptools ];

        disabledTestPaths = [ "old_tests/*.py" ];

        # Make `nix run` aware that the binary is called `ccm`.
        meta.mainProgram = "ccm";
      };
      make_wrapped = {pkgs} : pkgs.buildFHSUserEnv {
        name = "scylla_ccm";
        targetPkgs = pkgs: [(make_ccm_package { inherit pkgs; }) pkgs.jdk8 pkgs.jdk11];
        runScript = "ccm";
      };
    in
    flake-utils.lib.eachDefaultSystem (system:
      let 
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        packages = rec {
          scylla_ccm = make_wrapped {inherit pkgs;};
          default = scylla_ccm;
        };
        checks = {
          scylla_ccm_with_tests = make_wrapped {inherit pkgs; doCheck = true;};
        };
      }
    ) // rec {
      overlays.default = final: prev: {
        scylla_ccm = make_wrapped {pkgs = final;};
      };
    };
}
