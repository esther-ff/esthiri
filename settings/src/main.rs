use std::fs::File;
use std::io::{BufReader, BufWriter};

struct NixWriter {
    input: BufReader<File>,
    output: BufWriter<File>,
    state: (),
}

impl NixWriter {
    fn new() -> Self {
        let mut args = std::env::args();
        let _ = args.next();

        let niri_config_file = args
            .next()
            .expect("expected path to niri-config `lib.rs` as first argument");

        let output_nix_file = args
            .next()
            .expect("expected path to output *.nix file as first argument");

        let input =
            BufReader::new(File::open(&niri_config_file).expect("unable to open input file"));
        let output =
            BufWriter::new(File::open(output_nix_file).expect("unable to open output file"));

        Self {
            input,
            output,
            state: (),
        }
    }
}

fn main() {
    let mut nixxing = NixWriter::new();
}
