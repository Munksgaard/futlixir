{
  description = "Futlixir";

  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        pname = "futlixir";
        version = "0.1.0";
      in {
        packages = rec {
          futlixir = pkgs.beamPackages.mixRelease rec {
            inherit pname;
            inherit version;
            elixir = pkgs.elixir;

            buildInputs = [ pkgs.erlang ];

            nativeBuildInputs = [ pkgs.makeWrapper ];

            src = ./.;

            mixFodDeps = pkgs.beamPackages.fetchMixDeps {
              pname = "mix-deps-${pname}";
              inherit src version;
              sha256 = "5pdzmTgg3YgHheW+IR3visCuE6ITkXqj/BBTB09pfBE=";
            };

            installPhase = ''
              mix escript.build
              mkdir -p $out/bin
              mv ./futlixir $out/bin

              wrapProgram $out/bin/futlixir \
                --prefix PATH : ${pkgs.lib.makeBinPath [ elixir ]} \
                --set MIX_REBAR3 ${pkgs.rebar3}/bin/rebar3
            '';

            doCheck = true;

            checkPhase = ''
              mix test
            '';
          };
          default = futlixir;

        };

        devShells = rec {
          futlixir = pkgs.mkShell {
            buildInputs = [
              pkgs.erlang
              pkgs.elixir
              pkgs.elixir_ls
              pkgs.opencl-headers
              pkgs.ocl-icd
            ];

            shellHook = ''
              PS1="$PS1(${pname}) "
            '';

            C_INCLUDE_PATH = "${pkgs.erlang}/lib/erlang/usr/include/";
          };
          default = futlixir;
        };
      });
}
