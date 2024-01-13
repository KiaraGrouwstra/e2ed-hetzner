{ config, lib, pkgs, options, specialArgs, ... }:

let
  var = options.variable;
in rec {

  resource = {

    local_file.test_import = {
      filename = "test_import.txt";
      content = "A terranix created test file using imports. YEY!";
    };

  };

}
