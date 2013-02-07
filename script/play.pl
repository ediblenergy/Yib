#!/usr/bin/env perl
use strictures 1;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Yib::Sequencer;
use Data::Dumper::Concise;
my $data_dir = "$FindBin::Bin/../data";
sub wav {
    "$data_dir/wav/" . shift . ".wav";
}
sub mp3 {
    "$data_dir/mp3/" . shift . ".wav";
}
my @keys = (("a".."z"),("A".."Z"));
my $i = 0;
my %map;
for(qw[ a b c ]) {
    $map{$_} = shift(@ARGV);
}
warn Dumper \%map;
my $cfg = {
    keymap => {
        %map,
    }
};
my $yib = Yib::Sequencer->new( config => $cfg, bpm => 110);
eval {
    $yib->run;
};
if($@) {
    `stty sane`;
    die $@;
}
