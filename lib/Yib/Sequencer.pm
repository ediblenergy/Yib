package Yib::Sequencer;
use Moo;
use IO::Async::Loop::EV;
use IO::Async::Routine;
use Data::Dumper::Concise;
use Yib::Input::Keyboard;
use IO::Async::Timer::Periodic;
use Yib::Soundbank;
use Time::Hires;
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

has timer => ( is => 'lazy' );

has interval => ( is => 'lazy' );

sub _build_interval {
    my $self = shift;
    my $interval = 1 / ( $self->bpm / 60 );
    $interval = sprintf( "%.2f" => $interval);
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
sub tick {
    my $self = shift;
    $time_zero ||= Time::HiRes::time(); #kick off ze timer
    my $new_t = Time::HiRes::time();
    my $elapsed = $new_t - $time_zero;
    my $i = round( $elapsed / $self->interval );
    $self->soundbank->play_wav( $self->config->{keymap}{a}, 3 );
    if( !( $i % 2) ) {
        $self->soundbank->play_wav( $self->config->{keymap}{c}, 1 );
    }
    if( !( $i % 4) ) {
        $self->soundbank->play_wav( $self->config->{keymap}{d}, 2 );
    }
}
sub run {
    my $self = shift;
    warn "init keyboard: ".$self->keyboard;
    warn 'init timer';
    $self->timer;
    $self->loop->add( $self->timer );

    $self->loop->run;
}
1;
