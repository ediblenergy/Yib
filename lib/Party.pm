package Party;
use strictures 1;
use Moo;
use IO::Async::Loop;
use IO::Async::Routine;
use IO::Async::Channel;
use Term::ReadKey;
use Data::Dumper::Concise;

local $SIG{INT} = $SIG{HUP} = sub {
    ReadMode 'normal';
    `stty sane`;
};
has loop => ( is => 'lazy', default => sub { IO::Async::Loop->new } );
has routine => ( is => 'lazy' );
has keyboard => ( is => 'lazy' );
for (
    qw/
    in_ch
    out_ch
    keyin_ch
    keyout_ch
    /
  )
{
    has $_ => ( is => 'lazy', default => sub { 
            my $self = shift;
            IO::Async::Channel->new( 
                on_recv => sub {
                    my($channel,$data) = @_;
                    warn Dumper($data);
                    $self->$_($data);
                }
            );
        } 
    );
}
sub _build_routine {
    my $self   = shift;
    my $in_ch  = $self->in_ch;
    my $out_ch = $self->out_ch;
    my $loop   = $self->loop;

    my $routine = IO::Async::Routine->new(
        channels_in  => [$in_ch],
        channels_out => [$out_ch],
        code => sub {
            while (1) {
                my $msg = $in_ch->recv->{msg};
                warn $msg;

                # Can only send references
                $out_ch->send( \$msg );
            }
          },

        on_finish => sub {
            warn "The routine aborted early - $_[-1]";
            $loop->stop;
        },
    );

}

sub _keyboard_handler {
    my ( $keyin_ch, $keyout_ch ) = @_;
    sub {
        ReadMode 'cbreak';
        while (1) {
            my $char = ReadKey(0);
            warn $keyout_ch;
            warn $char;
            $keyout_ch->send( \$char );
        }
      }
}
sub _build_keyboard {
    my $self = shift;
    my $loop = $self->loop;
    my $keyin_ch = $self->keyin_ch;
    my $keyout_ch = $self->keyout_ch;
    $keyout_ch->on_recv(sub{ warn Dumper shift });
    my $routine = IO::Async::Routine->new(
#        channels_in => [$keyin_ch],
        channels_out => [$keyout_ch],
        code => _keyboard_handler($keyin_ch,$keyout_ch),
        on_finish => sub {
            warn "The routine aborted early - $_[-1]";
            $loop->stop;
        },
    );
}
sub keyout_ch {
    my($self,$data) = @_;
    warn Dumper $data;

}
#sub setup_listeners {
#    my $self = shift;
#    $self->keyout_ch->recv(
#        on_recv => sub {
#            warn 1;
#            my ( $ch, $totalref ) = @_;
#            warn Dumper($totalref);
#        }
#    );
#}
sub run {
    my $self = shift;
#    $self->loop->add( $self->routine );
    $self->loop->add( $self->keyboard );
    $self->setup_listeners;
#    $self->in_ch->send({ msg => 'hurdy gurdy'});
    $self->loop->run;
}


    
#use Carp;
#use SDL;
#use SDL::Audio;
#use SDL::Mixer;
#use SDL::Mixer::Samples;
#use SDL::Mixer::Channels;
#use SDL::Mixer::Music;
#
#SDL::init(SDL_INIT_AUDIO);
#unless ( SDL::Mixer::open_audio( 44100, AUDIO_S16SYS, 2, 4096 ) == 0 ) {
#    Carp::croak "Cannot open audio: " . SDL::get_error();
#}
#for (@ARGV) {
#    my $sample = SDL::Mixer::Samples::load_WAV($_);
#    unless ($sample) {
#        Carp::croak "Cannot load file data/sample.wav: " . SDL::get_error();
#    }
#    my $playing_channel = SDL::Mixer::Channels::play_channel( -1, $sample, 0 );
#    sleep 1;
#}
#SDL::Mixer::close_audio();
#SDL::quit;


1;
