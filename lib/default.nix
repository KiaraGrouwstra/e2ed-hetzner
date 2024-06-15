{lib, ...}: let
  # ".ext" -> ./subdir -> { "foo" = "<CONTENTS OF a/b/foo.ext>"; "bar" = "<CONTENTS OF a/b/bar.ext>"; }
  dirContents = let
    # ".ext" -> "a/b.ext" -> "b"
    fileAttrName = suffix: path:
      lib.removeSuffix suffix (builtins.baseNameOf path);

    # maps a file to a path
    # ".ext" -> "a/b" -> "c/d.ext" -> { name = "d"; value = "a/b/c/d.ext"; }
    fileAttrInPath = suffix: path: name: {
      name = fileAttrName suffix name;
      value = path + "/${name}";
    };

    # get an object of files in a directory with a given suffix
    # ".ext" -> "a/b" -> { "foo" = "a/b/foo.ext"; "bar" = "a/b/bar.ext"; }
    dirAttrs = suffix: path:
      lib.mapAttrs'
      (name: _: fileAttrInPath suffix path name)
      (lib.filterAttrs
        (name: type: lib.hasSuffix suffix name && type == "regular")
        (builtins.readDir path));
  in
    suffix: path: lib.mapAttrs (_: lib.readFile) (dirAttrs suffix path);

  mapKeys = f: lib.mapAttrs' (k: v: lib.nameValuePair (f k) v);

  mapVals = f: lib.mapAttrs (_: f);

  default = defaults: mapVals (v: defaults // v);

  inNamespace = prefix: mapKeys (k: "${prefix}_${k}");

  setNames = lib.mapAttrs (k: v: {name = k;} // v);
in
  assert mapKeys (k: k + k) {a = 1;} == {aa = 1;};
  assert mapVals (v: 2 * v) {a = 1;} == {a = 2;};
  assert default {b = 0;} {c = {a = 1;};}
  == {
    c = {
      b = 0;
      a = 1;
    };
  };
  assert inNamespace "b" {a = 1;} == {b_a = 1;};
  assert setNames {a = {v = 1;};}
  == {
    a = {
      name = "a";
      v = 1;
    };
  }; {
    inherit
      dirContents
      mapKeys
      mapVals
      default
      inNamespace
      setNames
    ;
  }
