{ lib, ... }:

let

  # ".ext" -> ./subdir -> { "foo" = "<CONTENTS OF a/b/foo.ext>"; "bar" = "<CONTENTS OF a/b/bar.ext>"; }
  dirContents = let

    # ".ext" -> "a/b.ext" -> "b"
    fileAttrName = suffix: path: let
      ext = lib.last (lib.splitString "." path);
    in lib.removeSuffix suffix (builtins.baseNameOf path);

    # maps a file to a path
    # ".ext" -> "a/b" -> "c/d.ext" -> { name = "d"; value = "a/b/c/d.ext"; }
    fileAttrInPath = suffix: path: name: {
      name = fileAttrName suffix name;
      value = path + "/${name}";
    };

    # get an object of files in a directory with a given suffix
    # ".ext" -> "a/b" -> { "foo" = "a/b/foo.ext"; "bar" = "a/b/bar.ext"; }
    dirAttrs = suffix: path: lib.mapAttrs'
      (name: _: fileAttrInPath suffix path name)
      (lib.filterAttrs
        (name: type: lib.hasSuffix suffix name && type == "regular")
        (builtins.readDir path));

  in suffix: path: lib.mapAttrs (_: lib.readFile) (dirAttrs suffix path);

in

{

  inherit dirContents;

}
