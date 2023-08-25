#!/bin/env raku

# reads in a file (ROM.bin.lst) (TODO should add symon too?)
sub MAIN() {
    my Str $inputfile="ROM.bin.lst";
    my $line;

    my $outputfilename="os_exports.mfk";
    my $output="// NOTE file created automatically from $inputfile by $?FILE\n\n";

    for $inputfile.IO.lines -> $line {
        $line ~~ /^^ (\w+) \s+ (\w)\:(\w\w\w\w) \s 'EXP' $$/;
        next unless $0;
        #$output ~= "const byte $0 = @0x$2\n" if $2.Str.parse-base(16) < 256;
        $output ~= "const word $0 = 0x$2\n" # if $2.Str.parse-base(16) >= 256;

    }
    say $output;
    $outputfilename.IO.spurt($output);
}
