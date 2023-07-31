#!/bin/env raku

# slurps in a file (ROM.s)
# searches for ;;;;AUTOEXPORT label hexoffset filename
sub MAIN(Str $inputfile) {
    my $text=$inputfile.IO.slurp;
    my $output="; NOTE file created automatically from $inputfile by $?FILE\n\n";


    my $t=~($text ~~ /';;;;AUTOEXPORT' .* ';;;;AUTOEXPORTEND'/);
    my @t=$t.lines;

    my $ilabel= @t[0].words[1];
    my $ihexoffset= @t[0].words[2].parse-base(16);
    my $ifilename= @t[0].words[3];

    say "Printing to $ifilename, using $ilabel as base at offset $ihexoffset";

    die "Problems parsing" if $ihexoffset==0 or $ilabel eq '' or $ifilename eq '';


    for @t[1..*] -> $t {
        $t ~~ /^^ (\w+) \: /;
        next unless $0;
         $output ~= "$0=$ilabel+\$" ~ $ihexoffset.base(16) ~ "\n";
        $ihexoffset+=3;
    }
    say $output;

    $ifilename.IO.spurt($output);
}
