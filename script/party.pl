use strictures 1;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Yib::Sequencer;
my $data_dir = "$FindBin::Bin/../data/";
sub wav {
    $data_dir . shift . ".wav";
}
my $cfg = {
    keymap => {
        w => wav('youraslacker'),
        a => wav('yourturn'),
        s => wav('intothefuture2'),
        d => wav('121gigawatts'),
    }
};
my $yib = Yib::Sequencer->new( config => $cfg);
$yib->run;
    
