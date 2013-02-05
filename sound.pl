use strict;
use warnings;
use SDL;
use Carp;
use SDL::Audio;
use SDL::Mixer;
use SDL::Mixer::Samples;
use SDL::Mixer::Channels;
use SDL::Mixer::Music;

SDL::init(SDL_INIT_AUDIO);
unless ( SDL::Mixer::open_audio( 44100, AUDIO_S16SYS, 2, 4096 ) == 0 ) {
    Carp::croak "Cannot open audio: " . SDL::get_error();
}
for (@ARGV) {
    my $sample = SDL::Mixer::Samples::load_WAV($_);
    unless ($sample) {
        Carp::croak "Cannot load file data/sample.wav: " . SDL::get_error();
    }
    my $playing_channel = SDL::Mixer::Channels::play_channel( -1, $sample, 0 );
    sleep 1;
}

sleep 3;
SDL::Mixer::close_audio();
SDL::quit;

