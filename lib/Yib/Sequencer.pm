package Yib::Sequencer;
use Moo;
use IO::Async::Loop::EV;
use IO::Async::Routine;
use Data::Dumper::Concise;
use Yib::Input::Keyboard;
use IO::Async::Timer::Periodic;
use Yib::Soundbank;
use Time::Hires;
use Yib::Pattern;

has keyboard => ( 
    is => 'lazy'
);

has loop => ( 
    is => 'ro',
    default => sub { IO::Async::Loop::EV->new },
);

has config => (
    is => 'ro',
    required => 1,
);

has soundbank => (
    is => 'lazy'
);

has bpm => (
    is => 'ro',
    required => 1,
);

has pattern_length => (
    is => 'ro',
    default => sub { 16 },
);

has timer => ( is => 'lazy' );

has interval => ( is => 'lazy' );

sub _build_interval {
    my $self = shift;
    warn $self->bpm;
    warn $self->bpm / 60;
    my $interval = ( 1 / ( $self->bpm / 60 )) * .25;
    $interval = sprintf( "%.2f" => $interval);
    warn $interval;
    return $interval;
}
sub _build_timer {
    #120 bpm = 2bps
    my $self = shift;
    my $timer = IO::Async::Timer::Periodic->new(
        interval => $self->interval,
        on_tick => sub {
            $self->tick();
        },
        reschedule => 'skip', #skip beats rather than drift
    );
    $timer->start;
    return $timer;
}
sub _build_soundbank {
    Yib::Soundbank->new;
}
sub _build_keyboard {
    my $self = shift;
    my $keyboard = Yib::Input::Keyboard->new( 
        loop => $self->loop, 
        on_recv => sub {
            $self->key_down(@_);
        }
    );
    $keyboard->init;
    return $keyboard;
}

sub key_down {
    my($self,$ref) = @_;
    my $key = $$ref;
    my $wav = $self->config->{keymap}{$key};
    $self->soundbank->play_wav($wav);
#    $self->soundbank->play_music($wav);
}
my $i = 0;
my $t = 0;
my $time_zero;
sub round {
    my $float = shift;
    my $rounded = int( $float + $float / abs( $float * 2 ) );
}
my ($bassdrum_pattern,$snare_pattern,$hihat_pattern);
sub tick {
    my $self = shift;
    $time_zero ||= Time::HiRes::time(); #kick off ze timer
    my $new_t = Time::HiRes::time();
    my $elapsed = $new_t - $time_zero;
    warn $self->interval;
    my $i = round( $elapsed / $self->interval) ;
    my $step = $i % $self->pattern_length;
    my $cur_step = ( 2 ** $step );
    if( $bassdrum_pattern->pattern & $cur_step ) {
        $self->soundbank->play_wav( $self->config->{keymap}{a}, 1 );
    }
    if( $snare_pattern->pattern & $cur_step ) {
        $self->soundbank->play_wav( $self->config->{keymap}{b}, 2 );
    }

    if( $hihat_pattern->pattern & $cur_step ) {
        $self->soundbank->play_wav( $self->config->{keymap}{c}, 3 );
    }
#    $self->soundbank->play_wav( $self->config->{keymap}{i}, 3 );
#    if( !( $i % 2) ) {
#    }
#    if( !( $i % 4) ) {
#        $self->soundbank->play_wav( $self->config->{keymap}{o}, 2 );
#    }
}
sub run {
    my $self = shift;
    warn "init keyboard: ".$self->keyboard;
    warn 'init timer';
    $bassdrum_pattern = Yib::Pattern->new( pattern => 0b1000_1100_0010_0010 );
    $snare_pattern    = Yib::Pattern->new( pattern => 0b0100_1000_0000_1000 );
    $hihat_pattern    = Yib::Pattern->new( pattern => 0b0010_0010_0010_0010 );

    $self->timer;
    $self->loop->add( $self->timer );

    $self->loop->run;
}
1;
