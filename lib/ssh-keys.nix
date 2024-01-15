{ lib, ... }:

let

    # "a/b.ext" -> "b"
    fileAttrName = path: let
      ext = lib.last (lib.splitString "." path);
    in lib.removeSuffix ".${ext}" (builtins.baseNameOf path);

    # maps a file to a path
    # "a/b" -> "c/d.ext" -> { name = "d"; value = "a/b/c/d.ext"; }
    fileAttrInPath = path: name: {
      name = fileAttrName name;
      value = path + "/${name}";
    };

    # get an object of files in a directory with a given suffix
    # "a/b" -> { "foo" = "a/b/foo.ext"; "bar" = "a/b/bar.ext"; }
    dirAttrs = suffix: path: lib.mapAttrs'
      (name: _: fileAttrInPath path name)
      (lib.filterAttrs
        (name: type: lib.hasSuffix suffix name && type == "regular")
        (builtins.readDir path));

  in lib.mapAttrs (_: lib.readFile) (dirAttrs ".pub" ../ssh-keys)
