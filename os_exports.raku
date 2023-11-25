#!/bin/env raku

# reads in a file (ROM.bin.lst) (TODO should add symon too?)
sub MAIN() {
    my Str $inputfile="ROM.bin.lst";
    my $line;
    my %stash;
    my $tabs="\t\t\t\t\t\t\t";

    my $outputfilename="millfork/include/bndr_os_exports.mfk";
    my $output="// NOTE file created automatically from $inputfile by $?FILE\n\n";
    my $temp="";

    for $inputfile.IO.lines -> $line {
        $line ~~ /^^ (\w+) \s+ (\w)\:(\w\w\w\w) \s 'EXP' $$/;
        next unless $0;
        #$output ~= "const byte $0 = @0x$2\n" if $2.Str.parse-base(16) < 256;
        my $name=$0.Str;
        my $val=$2.Str;
        %stash{$name}=$val;
    }

    for %stash.keys.sort -> $name {
        my $val=%stash{$name};
        my $pval=$val.parse-base(16);
#         if $pval < 0x200 or $pval >= 0x8000 { $temp ~= "const word $name = 0x$val\n";
#             } else { $temp ~= "const word $name = 0x$val\n";
#         }
        $temp ~= "const word $name = 0x$val\n";
    }

    my $max=0;
    for $temp.lines -> $line {
        my $l=$line.split("=");

        if $l.chars>$max { $max=$l.chars }
    }

    for $temp.lines -> $line {
        my ($l,$r)=$line.split("=");
        $l~= " " x ($max-$l.chars+1);
        $output~="$l=$r\n";
    }


    say $output;
    $outputfilename.IO.spurt($output);
}
