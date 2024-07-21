{lib, ...}: let
  # combine a list of functions to apply (left first)
  pipes = lib.flip lib.pipe;

  # combine a list of functions to apply (right first)
  compose = pipes [lib.reverseList pipes];

  # apply transforms from an attrset
  evolve = funs: vals: lib.mapAttrs (k: v: if lib.hasAttr k funs then let mapper = funs."${k}"; in (if lib.isAttrs mapper then evolve mapper v else mapper v) else v) vals;

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

  default = lib.attrsets.recursiveUpdate;

  defaults = lib.foldl' default {};

  inNamespace = prefix: mapKeys (k: "${prefix}_${k}");

  setFromKey = prop: lib.mapAttrs (k: v: {"${prop}" = k;} // v);
  setNames = setFromKey "name";

  tfRef = ref: "\${${ref}}";

  transforms = rec {
    id = resource: name: tfRef "hcloud_${resource}.${name}.id";
    placement_group_id = id "placement_group";
    network_id = id "network";
    firewall_id = id "firewall";
    firewall_ids = lib.lists.map firewall_id;
    server_id = id "server";
    volume_id = id "volume";
    assignee_id = server_id;
    server = server_id;
    server_ids = lib.lists.map server_id;
    label_selector = attr: lib.concatStringsSep "," (lib.attrsets.mapAttrsToList (name: value: "${name}=${value}") attr);
    label_selectors = lib.lists.map label_selector;
    apply_to = evolve { inherit server label_selector; };
    network = evolve { inherit network_id; };
  };

in
  assert pipes [(s: "(${s})") (s: s + s)] "foo" == "(foo)(foo)";
  assert compose [(s: s + s) (s: "(${s})")] "foo" == "(foo)(foo)";
  assert evolve {a=v: v+1;b.c=v: v+v;} { a=1; b.c="c"; d=true; } == { a=2; b.c="cc"; d=true; };
  assert mapKeys (k: k + k) {a = 1;} == {aa = 1;};
  assert mapVals (v: 2 * v) {a = 1;} == {a = 2;};
  assert default {b = 0;} {a = 1;}
  == {
    b = 0;
    a = 1;
  };
  assert inNamespace "b" {a = 1;} == {b_a = 1;};
  assert setNames {a = {v = 1;};}
  == {
    a = {
      name = "a";
      v = 1;
    };
  };
  assert transforms.server_id "foo" == "\${hcloud_server.foo.id}";
  assert transforms.label_selector {a="1";b="2";} == "a=1,b=2";
  {
    inherit
      pipes
      compose
      evolve
      dirContents
      mapKeys
      mapVals
      default
      defaults
      inNamespace
      setFromKey
      setNames
      transforms
    ;
  }
