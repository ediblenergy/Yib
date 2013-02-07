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

use Devel::REPL;

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

has patterns => (
    is => 'ro',
    default => sub { [] },
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
    $time_zero ||= Time::HiRes::time();    #kick off ze timer
    my $new_t    = Time::HiRes::time();
    my $elapsed  = $new_t - $time_zero;
    my $i        = round( $elapsed / $self->interval );
    my $step     = $i % $self->pattern_length;
    my $cur_step = ( 2**$step );
    for ( @{ $self->patterns } ) {

        if ( $_->pattern & $cur_step ) {
            $self->soundbank->play_wav(
                $self->config->{keymap}{ $_->trigger },
                $_->channel
            );
        }
    }
}
sub run {
    my $self = shift;
    warn "init keyboard: ".$self->keyboard;
    warn 'init timer';
    push(
          @{ $self->patterns } =>
            Yib::Pattern->new(
                               pattern => 0b1000_1000_0010_0010,
                               trigger => 'a',
                               channel => 1,
                               name    => 'bassdrum',
                             ) );

    push(
          @{ $self->patterns } =>
            Yib::Pattern->new(
                               pattern => 0b0100_1000_0000_1000,
                               trigger => 'b',
                               channel => 2,
                               name    => 'snare',
                             ) );
    push(
          @{ $self->patterns } =>
            Yib::Pattern->new(
                               pattern => 0b1010_1010_1010_1010,
                               trigger => 'c',
                               channel => 3,
                               name    => 'hihat',
                             ) );
    $self->timer;
    $self->loop->add( $self->timer );
    $self->loop->run;
}
1;
