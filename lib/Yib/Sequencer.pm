package Yib::Sequencer;
use Moo;
use IO::Async::Loop::EV;
use IO::Async::Loop;
use IO::Async::Routine;
use Data::Dumper::Concise;
use Yib::Input::Keyboard;
use Yib::Soundbank;

has keyboard => ( 
    is => 'lazy'
);

has loop => ( 
    is => 'ro',
    default => sub { IO::Async::Loop->new },
);

has config => (
    is => 'ro',
    required => 1,
);

has soundbank => (
    is => 'lazy'
);

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
}

sub key_down {
    my($self,$ref) = @_;
    my $key = $$ref;
    my $wav = $self->config->{keymap}{$key};
    $self->soundbank->play_wav($wav);
}

sub run {
    my $self = shift;
    warn "init keyboard: ".$self->keyboard;
    $self->loop->run;
}
1;
