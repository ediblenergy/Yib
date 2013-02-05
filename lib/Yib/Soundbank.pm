package Yib::Soundbank;
use Moo;
use Carp;
use SDL;
use SDL::Audio;
use SDL::Mixer;
use SDL::Mixer::Samples;
use SDL::Mixer::Channels;
use SDL::Mixer::Music;

SDL::init(SDL_INIT_AUDIO);
unless ( SDL::Mixer::open_audio( 44100, AUDIO_S16SYS, 2, 4096 ) == 0 ) {
    Carp::croak "Cannot open audio: " . SDL::get_error();
}

sub play_wav {
    my ( $self, $file ) = @_;
    my $sample = SDL::Mixer::Samples::load_WAV($file);
    unless ($sample) {
        Carp::croak "Cannot load file data/sample.wav: " . SDL::get_error();
    }
    my $playing_channel = SDL::Mixer::Channels::play_channel( -1, $sample, 0 );
}

sub DESTROY {
    SDL::Mixer::close_audio();
    SDL::quit;
}

1;
