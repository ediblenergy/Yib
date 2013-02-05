package Yib::Input::Keyboard;
use Moo;
use IO::Async::Loop::EV;
use IO::Async::Loop;
use IO::Async::Routine;
use IO::Async::Channel;
use Data::Dumper::Concise;
use Term::ReadKey;
warn __PACKAGE__;

has keyboard_listener => ( is => 'lazy' );

has loop => ( 
    is => 'ro',
    default => sub { IO::Async::Loop::EV->new },
);

has keyout_ch => ( 
    is => 'ro',
    default => sub { IO::Async::Channel->new },
);

has on_recv => (
    is => 'ro',
    required => 1,
);

sub _build_keyboard_listener {
    my $self = shift;
    my $keyout_ch = $self->keyout_ch;
    my $routine = IO::Async::Routine->new(
        channels_out => [ $keyout_ch ],
        code => sub {
            my $i = 0;
            ReadMode 'cbreak';
            while(1) {
                $i++;
                my $char = ReadKey(0);
                $keyout_ch->send( \$char );
            }
        },
        on_finish => sub {
            warn Dumper \@_;
        }
    );
    return $routine;
}

sub init {
    my $self = shift;
    my $loop = $self->loop;
    my $keyout_ch = $self->keyout_ch;
    my $keyboard_listener = $self->keyboard_listener;
    $loop->add($keyboard_listener);
    $keyout_ch->configure(
        on_recv => sub {
            my ( $ch, $ref ) = @_;
            $self->on_recv->($ref);
        }
    );
}
#sub run {
#    my $self = shift;
#    my $loop = $self->loop;
#    my $keyout_ch = $self->keyout_ch;
#    my $keyboard_listener = $self->keyboard_listener;
#    $loop->add($keyboard_listener);
#    $keyout_ch->configure(
#        on_recv => sub {
#            my ( $ch, $ref ) = @_;
#            warn "received: $$ref";
#        }
#    );
#    warn 'running loop...';
#    $loop->run;
#}
1;
