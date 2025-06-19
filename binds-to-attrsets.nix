# `actions` should be a string representing a path to `$src/niri-config/src/lib.rs`
lib: actions:
let
  inherit (lib) length elemAt readFile splitString sublist trim;

  openFile = splitString "\n" (readFile (builtins.toPath actions));
  numOfLines = length openFile;

  # As of 19th June 2025, the `Action` enum starts at line 1674 in `lib.rs`
  # this trick allows skipping a lot of recursion.
  # This could cut to the exact line, however i want to keep a "buffer" for possible movement
  # of this enum, as to not create problems it it moves by (for example) 1 line or 2.
  cutOff = sublist 1600 numOfLines openFile;

  skipToAction = list: index:
    if elemAt list index == "pub enum Action {" then
      map (elem: trim elem) (sublist (index + 1) numOfLines list)
    else
      skipToAction list (index + 1);

  actualList = skipToAction cutOff 0;

  parse = actionList:
    let
      innerParse = list: accum: index:
        if elemAt list index == "}" then
          accum
        else
          innerParse list (accum ++ [ (elemAt list index) ]) (index + 1);
    in innerParse actionList [ ] 0;

in { test = parse actualList; }
